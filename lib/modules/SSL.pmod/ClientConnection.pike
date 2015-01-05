#pike __REAL_VERSION__
#pragma strict_types
#require constant(SSL.Cipher)

//! Client-side connection state.

#ifdef SSL3_DEBUG
#define SSL3_DEBUG_MSG(X ...)  werror(X)
#else
#define SSL3_DEBUG_MSG(X ...)
#endif

import ".";
import Constants;
inherit Connection;

//! A few storage variables for client certificate handling on the client side.
array(int) client_cert_types;
array(string(8bit)) client_cert_distinguished_names;

protected string _sprintf(int t)
{
  if (t == 'O') return sprintf("SSL.ClientConnection(%s)", describe_state());
}

//!
Packet client_hello(string(8bit)|void server_name)
{
  Buffer struct = Buffer();
  /* Build client_hello message */
  client_version = version;
  struct->add_int(client_version, 2); /* version */

  // The first four bytes of the client_random is specified to be the
  // timestamp on the client side. This is to guard against bad random
  // generators, where a client could produce the same random numbers
  // if the seed is reused. This argument is flawed, since a broken
  // random generator will make the connection insecure anyways. The
  // standard explicitly allows these bytes to not be correct, so
  // sending random data instead is safer and reduces client
  // fingerprinting.
  client_random = context->random(32);

  struct->add(client_random);
  struct->add_hstring(session->identity || "", 1);

  array(int) cipher_suites, compression_methods;
  cipher_suites = context->preferred_suites;
  if ((state & CONNECTION_handshaking) && !secure_renegotiation) {
    // Initial handshake.
    // Use the backward-compat way of asking for
    // support for secure renegotiation.
    cipher_suites += ({ TLS_empty_renegotiation_info_scsv });

    if (client_version < context->max_version) {
      // Negotiating a version lower than the max supported version.
      //
      // draft-ietf-tls-downgrade-scsv 4:
      // If a client sends a ClientHello.client_version containing a lower
      // value than the latest (highest-valued) version supported by the
      // client, it SHOULD include the TLS_FALLBACK_SCSV cipher suite value
      // in ClientHello.cipher_suites.  (Since the cipher suite list in the
      // ClientHello is ordered by preference, with the client's favorite
      // choice first, signaling cipher suite values will generally appear
      // after all cipher suites that the client actually intends to
      // negotiate.)
      cipher_suites += ({ TLS_fallback_scsv });
    }
  }
  SSL3_DEBUG_MSG("Client ciphers:\n%s",
                 fmt_cipher_suites(cipher_suites));
  if (client_version >= PROTOCOL_TLS_1_3) {
    // TLS 1.3 (draft 3) does not allow any compression.
    compression_methods = ({ COMPRESSION_null });
  } else {
    compression_methods = context->preferred_compressors;
  }

  struct->add_int_array(cipher_suites, 2, 2);
  struct->add_int_array(compression_methods, 1, 1);

  Buffer extensions = Buffer();

  void ext(int id, int condition, function(void:Buffer) code)
  {
    if(condition)
    {
      extensions->add_int(id, 2);
      extensions->add_hstring(code(), 2);
    }
  };

  ext (EXTENSION_renegotiation_info, secure_renegotiation) {
    // RFC 5746 3.4:
    // The client MUST include either an empty "renegotiation_info"
    // extension, or the TLS_EMPTY_RENEGOTIATION_INFO_SCSV signaling
    // cipher suite value in the ClientHello.  Including both is NOT
    // RECOMMENDED.
    return Buffer()->add_hstring(client_verify_data, 1);
  };

  ext (EXTENSION_elliptic_curves,
       sizeof(context->ecc_curves)||sizeof(context->ffdhe_groups)) {
    // RFC 4492 5.1:
    // The extensions SHOULD be sent along with any ClientHello message
    // that proposes ECC cipher suites.
    Buffer curves = Buffer();
    foreach(context->ecc_curves, int curve) {
      curves->add_int(curve, 2);
    }
    // FFDHE draft 4 3:
    //   The compatible client that wants to be able to negotiate
    //   strong FFDHE SHOULD send a "Supported Groups" extension
    //   (identified by type elliptic_curves(10) in [RFC4492]) in the
    //   ClientHello, and include a list of known FFDHE groups in the
    //   extension data, ordered from most preferred to least preferred.
    //
    // NB: The ffdhe_groups in the context has the smallest group first,
    //     so we reverse it here in case the server actually follows
    //     our priority order.
    foreach(reverse(context->ffdhe_groups), int group) {
      curves->add_int(group, 2);
    }
    // FIXME: FFDHE draft 4 6.1:
    //   More subtly, clients MAY interleave preferences between ECDHE
    //   and FFDHE groups, for example if stronger groups are
    //   preferred regardless of cost, but weaker groups are
    //   acceptable, the Supported Groups extension could consist of:
    //   <ffdhe8192,secp384p1,ffdhe3072,secp256r1>. In this example,
    //   with the same CipherSuite offered as the previous example, a
    //   server configured to respect client preferences and with
    //   support for all listed groups SHOULD select
    //   TLS_DHE_RSA_WITH_AES_128_CBC_SHA with ffdhe8192. A server
    //   configured to respect client preferences and with support for
    //   only secp384p1 and ffdhe3072 SHOULD select
    //   TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA with secp384p1.
    return Buffer()->add_hstring(curves, 2);
  };

  ext (EXTENSION_ec_point_formats, sizeof(context->ecc_curves)) {
    Buffer point = Buffer();
    point->add_int(POINT_uncompressed, 1);
    return Buffer()->add_hstring(point, 1);
  };

  // We always attempt to enable the heartbeat extension.
  ext (EXTENSION_heartbeat, 1) {
    // RFC 6420
    return Buffer()->add_int(HEARTBEAT_MODE_peer_allowed_to_send, 1);
  };

  ext (EXTENSION_encrypt_then_mac, context->encrypt_then_mac) {
    // draft-ietf-tls-encrypt-then-mac
    return Buffer();
  };

  ext (EXTENSION_signature_algorithms, client_version >= PROTOCOL_TLS_1_2) {
    // RFC 5246 7.4.1.4.1:
    // If the client supports only the default hash and signature algorithms
    // (listed in this section), it MAY omit the signature_algorithms
    // extension.  If the client does not support the default algorithms, or
    // supports other hash and signature algorithms (and it is willing to
    // use them for verifying messages sent by the server, i.e., server
    // certificates and server key exchange), it MUST send the
    // signature_algorithms extension, listing the algorithms it is willing
    // to accept.

    // We list all hashes and signature formats that we support.
    return Buffer()->add_hstring(get_signature_algorithms(), 2);
  };

  ext (EXTENSION_server_name, !!server_name)
  {
    Buffer hostname = Buffer();
    hostname->add_int(0, 1); // name_time host_name(0)
    hostname->add_hstring(server_name, 2); // hostname

    return Buffer()->add_hstring(hostname, 2);
  };

  ext (EXTENSION_application_layer_protocol_negotiation, !!(context->advertised_protocols))
  {
    return Buffer()->add_string_array(context->advertised_protocols, 1, 2);
  };

  // When the client HELLO packet data is in the range 256-511 bytes
  // f5 SSL terminators will intepret it as SSL2 requiring an
  // additional 8k of data, which will cause the connection to hang.
  // The solution is to pad the package to more than 511 bytes using a
  // dummy exentsion.
  // Reference: draft-agl-tls-padding
  int packet_size = sizeof(struct)+sizeof(extensions)+2;
  ext (EXTENSION_padding, packet_size>255 && packet_size<512)
  {
    int padding = max(0, 512-packet_size-4);
    SSL3_DEBUG_MSG("SSL.ClientConnection: Adding %d bytes of padding.\n",
                   padding);
    return Buffer()->add("\0"*padding);
  };

  if(sizeof(extensions) && (version >= PROTOCOL_TLS_1_0))
    struct->add_hstring(extensions, 2);

  SSL3_DEBUG_MSG("SSL.ClientConnection: Client hello: %q\n", struct);
  return handshake_packet(HANDSHAKE_client_hello, struct);
}

Packet finished_packet(string(8bit) sender)
{
  SSL3_DEBUG_MSG("Sending finished_packet, with sender=\""+sender+"\"\n" );
  // We're the client.
  client_verify_data = hash_messages(sender);
  return handshake_packet(HANDSHAKE_finished, client_verify_data);
}

Packet client_key_exchange_packet()
{
  ke = ke || session->cipher_spec->ke_factory(context, session, this, client_version);
  string(8bit) data =
    ke->client_key_exchange_packet(client_random, server_random, version);
  if (!data) {
    send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
		      "Invalid KEX.\n"));
    return 0;
  }

  array(State) res =
    session->new_client_states(this, client_random, server_random, version);
  pending_read_state = res[0];
  pending_write_state = res[1];

  return handshake_packet(HANDSHAKE_client_key_exchange, data);
}

//! Initialize a new @[ClientConnection].
//!
//! @param ctx
//!   @[Context] to use.
//!
//! @param server_name
//!   Optional host name of the server.
//!
//! @param session
//!   Optional @[Session] to resume.
protected void create(Context ctx, string(8bit)|void server_name,
		      Session|void session)
{
  ::create(ctx);
  handshake_state = STATE_wait_for_hello;
  handshake_messages = "";
  this_program::session = session || Session();
  if (!this_program::session->ffdhe_groups) {
    this_program::session->ffdhe_groups = ctx->ffdhe_groups;
  }
  send_packet(client_hello(server_name));
}

//! Renegotiate the connection (client initiated).
//!
//! Sends a @[client_hello] to force a new round of handshaking.
void send_renegotiate()
{
  send_packet(client_hello(), PRI_application);
}

//! Do handshake processing. Type is one of HANDSHAKE_*, data is the
//! contents of the packet, and raw is the raw packet received (needed
//! for supporting SSLv2 hello messages).
//!
//! This function returns 0 if handshake is in progress, 1 if handshake
//! is finished, and -1 if a fatal error occurred. It uses the
//! send_packet() function to transmit packets.
int(-1..1) handle_handshake(int type, string(8bit) data, string(8bit) raw)
{
  Buffer input = Buffer(data);
#ifdef SSL3_PROFILING
  addRecord(type,0);
#endif
#ifdef SSL3_DEBUG_HANDSHAKE_STATE
  werror("SSL.ClientConnection: state %s, type %s\n",
	 fmt_constant(handshake_state, "STATE"),
         fmt_constant(type, "HANDSHAKE"));
  werror("sizeof(data)="+sizeof(data)+"\n");
#endif

  switch(handshake_state)
  {
  default:
    error( "Internal error\n" );
  case STATE_wait_for_hello:
    if(type != HANDSHAKE_server_hello)
    {
      send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
			"Expected server hello.\n"));
      return -1;
    }
    else
    {
      SSL3_DEBUG_MSG("SSL.ClientConnection: SERVER_HELLO\n");

      handshake_messages += raw;
      string(8bit) id;
      int cipher_suite, compression_method;

      version = [int(0x300..0x300)|ProtocolVersion]input->read_int(2);
      server_random = input->read(32);
      id = input->read_hstring(1);
      cipher_suite = input->read_int(2);
      compression_method = input->read_int(1);

      if( !has_value(context->preferred_suites, cipher_suite) ||
	  !has_value(context->preferred_compressors, compression_method) ||
	  !session->is_supported_suite(cipher_suite, ~0, version))
      {
	// The server tried to trick us to use some other cipher suite
	// or compression method than we wanted
	version = client_version;
	send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
			  "Server selected bad suite.\n"));
	return -1;
      }

      if (((version & ~0xff) != PROTOCOL_SSL_3_0) ||
	  (version < context->min_version)) {
	SSL3_DEBUG_MSG("Unsupported version of SSL: %s.\n",
		       fmt_version(version));
	version = client_version;
	send_packet(alert(ALERT_fatal, ALERT_protocol_version,
			  "Unsupported version.\n"));
	return -1;
      }
      if (client_version > version) {
	SSL3_DEBUG_MSG("Falling back client from %s to %s.\n",
		       fmt_version(client_version),
		       fmt_version(version));
      } else if (version > client_version) {
	SSL3_DEBUG_MSG("Falling back server from %s to %s.\n",
		       fmt_version(version),
		       fmt_version(client_version));
	version = client_version;
      }

      if (!session->set_cipher_suite(cipher_suite, version,
				     context->signature_algorithms,
				     512)) {
	// Unsupported or obsolete cipher suite selected.
	send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
			  "Unsupported or obsolete cipher suite.\n"));
	return -1;
      }

      if (version >= PROTOCOL_TLS_1_3 && compression_method!=COMPRESSION_null)
      {
	send_packet(alert(ALERT_fatal, ALERT_insufficient_security,
			  "Compression not supported in TLS 1.3 and later.\n"));
	return -1;
      }
      session->set_compression_method(compression_method);

      SSL3_DEBUG_MSG("STATE_wait_for_hello: received hello\n"
		     "version = %s\n"
		     "id=%O\n"
		     "cipher suite: %O\n"
		     "compression method: %O\n",
		     fmt_version(version),
		     id, cipher_suite, compression_method);

      int missing_secure_renegotiation = secure_renegotiation;

      if (sizeof(input)) {
	Stdio.Buffer extensions = input->read_hbuffer(2);
        multiset(int) remote_extensions = (<>);

	while (sizeof(extensions)) {
	  int extension_type = extensions->read_int(2);
	  Buffer extension_data =
	    Buffer(extensions->read_hstring(2));
	  SSL3_DEBUG_MSG("SSL.ClientConnection->handle_handshake: "
			 "Got extension %s.\n",
			 fmt_constant(extension_type, "EXTENSION"));
          if( remote_extensions[extension_type] )
          {
            send_packet(alert(ALERT_fatal, ALERT_decode_error,
                              "Same extension sent twice.\n"));
            return -1;
          }
          else
            remote_extensions[extension_type] = 1;

	  switch(extension_type) {
	  case EXTENSION_renegotiation_info:
	    string renegotiated_connection = extension_data->read_hstring(1);
	    if ((renegotiated_connection !=
		 (client_verify_data + server_verify_data)) ||
		(!(state & CONNECTION_handshaking) && !secure_renegotiation)) {
	      // RFC 5746 3.5: (secure_renegotiation)
	      // The client MUST then verify that the first half of the
	      // "renegotiated_connection" field is equal to the saved
	      // client_verify_data value, and the second half is equal to the
	      // saved server_verify_data value.  If they are not, the client
	      // MUST abort the handshake.
	      //
	      // RFC 5746 4.2: (!secure_renegotiation)
	      // When the ServerHello is received, the client MUST
	      // verify that it does not contain the
	      // "renegotiation_info" extension. If it does, the client
	      // MUST abort the handshake. (Because the server has
	      // already indicated it does not support secure
	      // renegotiation, the only way that this can happen is if
	      // the server is broken or there is an attack.)
	      send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
				"Invalid renegotiation data.\n"));
	      return -1;
	    }
	    secure_renegotiation = 1;
	    missing_secure_renegotiation = 0;
	    break;
	  case EXTENSION_ec_point_formats:
	    array(int) ecc_point_formats =
	      extension_data->read_int_array(1, 1);
	    // NB: We only support the uncompressed point format for now.
	    if (has_value(ecc_point_formats, POINT_uncompressed)) {
	      session->ecc_point_format = POINT_uncompressed;
	    } else {
	      // Not a supported point format.
	      session->ecc_point_format = -1;
	    }
	    break;
	  case EXTENSION_server_name:
            break;

	  case EXTENSION_heartbeat:
	    {
	      int hb_mode;
	      if (!sizeof(extension_data) ||
		  !(hb_mode = extension_data->read_int(1)) ||
		  sizeof(extension_data) ||
		  ((hb_mode != HEARTBEAT_MODE_peer_allowed_to_send) &&
		   (hb_mode != HEARTBEAT_MODE_peer_not_allowed_to_send))) {
		// RFC 6520 2:
		// Upon reception of an unknown mode, an error Alert
		// message using illegal_parameter as its
		// AlertDescription MUST be sent in response.
		send_packet(alert(ALERT_fatal, ALERT_illegal_parameter,
				  "Invalid heartbeat extension.\n"));
                return -1;
	      }
	      SSL3_DEBUG_MSG("heartbeat extension: %s\n",
			     fmt_constant(hb_mode, "HEARTBEAT_MODE"));
	      session->heartbeat_mode = [int(0..1)]hb_mode;
	    }
	    break;

	  case EXTENSION_encrypt_then_mac:
	    {
	      if (context->encrypt_then_mac) {
		if (sizeof(extension_data)) {
		  send_packet(alert(ALERT_fatal, ALERT_illegal_parameter,
				    "Encrypt-then-MAC: Invalid extension.\n"));
                  return -1;
		}
		if (((sizeof(CIPHER_SUITES[cipher_suite]) == 3) &&
		     (< CIPHER_rc4, CIPHER_rc4_40 >)[CIPHER_SUITES[cipher_suite][1]]) ||
		    ((sizeof(CIPHER_SUITES[cipher_suite]) == 4) &&
		     (CIPHER_SUITES[cipher_suite][3] != MODE_cbc))) {
		  send_packet(alert(ALERT_fatal, ALERT_illegal_parameter,
				    "Encrypt-then-MAC: Invalid for selected suite.\n"));
                  return -1;
		}

		SSL3_DEBUG_MSG("Encrypt-then-MAC: Enabled.\n");
		session->encrypt_then_mac = 1;
		break;
	      }
	      /* We didn't request the extension, so complain loudly. */
	    }
	    /* FALL_THROUGH */

	  default:
	    // RFC 5246 7.4.1.4:
	    // If a client receives an extension type in ServerHello
	    // that it did not request in the associated ClientHello, it
	    // MUST abort the handshake with an unsupported_extension
	    // fatal alert.
	    send_packet(alert(ALERT_fatal, ALERT_unsupported_extension,
			      "Unrequested extension.\n"));
	    return -1;
	  }
	}
      }
      if (missing_secure_renegotiation) {
	// RFC 5746 3.5:
	// When a ServerHello is received, the client MUST verify that the
	// "renegotiation_info" extension is present; if it is not, the
	// client MUST abort the handshake.
	send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
			  "Missing secure renegotiation extension.\n"));
	return -1;
      }

      if ((id == session->identity) && sizeof(id)) {
	SSL3_DEBUG_MSG("Resuming session %O.\n", id);
	array(State) res =
	  session->new_client_states(this, client_random, server_random,
				     version);
	pending_read_state = res[0];
	pending_write_state = res[1];

	handshake_state = STATE_wait_for_finish;
	expect_change_cipher = 1;
	reuse = 1;
	break;
      }

      session->identity = id;
      handshake_state = STATE_wait_for_peer;
      break;
    }
    break;

  case STATE_wait_for_peer:
    handshake_messages += raw;
    switch(type)
    {
    default:
      send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
			"Unexpected server message.\n"));
      return -1;
    case HANDSHAKE_certificate:
      {
	SSL3_DEBUG_MSG("SSL.ClientConnection: Certificate recevied\n");

        // we're anonymous, so no certificate is requred.
        if(ke && ke->anonymous)
          break;

        Stdio.Buffer cert_data = input->read_hbuffer(3);
        array(string(8bit)) certs = ({ });
        while(sizeof(cert_data))
          certs += ({ cert_data->read_hstring(3) });

        // we have the certificate chain in hand, now we must verify
        // them.
        if(!verify_certificate_chain(certs))
        {
          send_packet(alert(ALERT_fatal, ALERT_bad_certificate,
                            "Bad server certificate chain.\n"));
          return -1;
        }

        session->peer_certificate_chain = certs;

        mixed error=catch
          {
            session->peer_public_key = Standards.X509.decode_certificate(
                session->peer_certificate_chain[0])->public_key->pkc;
#if constant(Crypto.ECC.Curve)
            if (session->peer_public_key->curve) {
              session->curve =
                ([object(Crypto.ECC.SECP_521R1.ECDSA)]session->peer_public_key)->
                curve();
            }
#endif
          };

        if(error)
	{
	  session->peer_certificate_chain = UNDEFINED;
	  send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
			    "Failed to decode server certificate.\n"));
	  return -1;
	}

        certificate_state = CERT_received;
        break;
      }

    case HANDSHAKE_server_key_exchange:
      {
	if (ke) error("KE!\n");
	ke = session->cipher_spec->ke_factory(context, session, this, client_version);
	if (ke->server_key_exchange(input, client_random, server_random) < 0) {
	  send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
			    "Verification of ServerKeyExchange failed.\n"));
	  return -1;
	}
	break;
      }

    case HANDSHAKE_certificate_request:
      {
        SSL3_DEBUG_MSG("SSL.ClientConnection: CERTIFICATE_REQUEST\n");

        // it is a fatal handshake_failure alert for an anonymous server to
        // request client authentication.
        if(ke->anonymous)
        {
	  send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
			    "Anonymous server requested authentication by "
			    "certificate.\n"));
	  return -1;
        }

        client_cert_types = input->read_int_array(1, 1);
        client_cert_distinguished_names = ({});

	if (version >= PROTOCOL_TLS_1_2) {
	  // TLS 1.2 has var_uint_array of hash and sign pairs here.
	  string bytes = input->read_hstring(2);
          if( sizeof(bytes)&1 )
          {
            send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
                              "Odd number of bytes in "
                              "supported_signature_algorithms.\n"));
            return -1;
          }
	  // Pairs of <hash_alg, signature_alg>.
	  session->signature_algorithms = ((array(int))bytes)/2;
	  SSL3_DEBUG_MSG("New signature_algorithms:\n"+
			 fmt_signature_pairs(session->signature_algorithms));
	}

        Stdio.Buffer s = input->read_hbuffer(2);
        while(sizeof(s))
        {
          string(8bit) der = s->read_hstring(2);
          Standards.ASN1.Types.Object o =
            Standards.ASN1.Decode.secure_der_decode(der);
          if( o->type_name != "SEQUENCE" )
          {
            send_packet(alert(ALERT_fatal, ALERT_handshake_failure,
                              "Badly formed Certificate Request.\n"));
            return -1;
          }
          client_cert_distinguished_names += ({ der });
          SSL3_DEBUG_MSG("got an authorized issuer: %O\n",
                         Standards.PKCS.Certificate.get_dn_string
                         ( [object(Standards.ASN1.Types.Sequence)]o ));
        }

        break;
      }

    case HANDSHAKE_server_hello_done:
      SSL3_DEBUG_MSG("SSL.ClientConnection: SERVER_HELLO_DONE\n");

      /* Send Certificate, ClientKeyExchange, CertificateVerify and
       * ChangeCipherSpec as appropriate, and then Finished.
       */
      CertificatePair cert;

      /* only send a certificate if it's been requested. */
      if(client_cert_types)
      {
	SSL3_DEBUG_MSG("Searching for a suitable client certificate...\n");

        // Okay, we have a list of certificate types and DN:s that are
        // acceptable to the remote server. We should weed out the certs
        // we have so that we only send certificates that match what they
        // want.

	SSL3_DEBUG_MSG("All certs: %O\n"
		       "distinguished_names: %O\n",
		       context->get_certificates(),
		       client_cert_distinguished_names);

	array(CertificatePair) certs =
	  context->find_cert_issuer(client_cert_distinguished_names) || ({});

	certs = [array(CertificatePair)]
          filter(certs,
		 lambda(CertificatePair cp, array(int)) {
                   // FIXME: Needs to look at session->signature_algorithms.
		   return has_value(client_cert_types, cp->cert_type);
		 }, client_cert_types);

	if (sizeof(certs)) {
	  SSL3_DEBUG_MSG("Found %d matching client certs.\n", sizeof(certs));
	  cert = certs[0];
	  session->private_key = cert->key;
          session->certificate_chain = cert->certs;
	  send_packet(certificate_packet(session->certificate_chain));
	} else {
	  SSL3_DEBUG_MSG("No suitable client certificate found.\n");
	  send_packet(certificate_packet(({})));
	}
      }

      if( !session->has_required_certificates() )
      {
        send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
                          "Certificate message missing.\n"));
        return -1;
      }

      Packet key_exchange = client_key_exchange_packet();

      if (key_exchange)
	send_packet(key_exchange);


      // FIXME: The certificate code has changed, so this no longer
      // works, if it ever did.

      // FIXME: Certificate verify; we should redo this so it makes more sense
      if(cert) {
         // we sent a certificate, so we should send the verification.
         send_packet(certificate_verify_packet());
      }

      send_packet(change_cipher_packet());

      if(version == PROTOCOL_SSL_3_0)
	send_packet(finished_packet("CLNT"));
      else if(version >= PROTOCOL_TLS_1_0)
	send_packet(finished_packet("client finished"));

      // NB: The server direction hash will be calculated
      //     when we've received the server finished packet.

      if (context->heartbleed_probe &&
          session->heartbeat_mode == HEARTBEAT_MODE_peer_allowed_to_send) {
	// Probe for the Heartbleed vulnerability (CVE-2014-0160).
	send_packet(heartbleed_packet());
      }

      handshake_state = STATE_wait_for_finish;
      expect_change_cipher = 1;
      break;
    }
    break;

  case STATE_wait_for_finish:
    {
      if(type != HANDSHAKE_finished)
      {
        SSL3_DEBUG_MSG("Expected type HANDSHAKE_finished(%d), got %d\n",
                       HANDSHAKE_finished, type);
        send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
                          "Expected handshake finished.\n"));
        return -1;
      }

      SSL3_DEBUG_MSG("SSL.ClientConnection: FINISHED\n");

      string my_digest;
      if (version == PROTOCOL_SSL_3_0) {
        server_verify_data = input->read(36);
        my_digest = hash_messages("SRVR");
      } else if (version >= PROTOCOL_TLS_1_0) {
        server_verify_data = input->read(12);
        my_digest = hash_messages("server finished");
      }

      if (my_digest != server_verify_data) {
        send_packet(alert(ALERT_fatal, ALERT_unexpected_message,
                          "Digests differ.\n"));
        return -1;
      }

      handshake_state = STATE_handshake_finished;

      if (reuse) {
	send_packet(change_cipher_packet());

	handshake_messages += raw; /* Second hash includes this message,
				    * the first doesn't */

	if(version == PROTOCOL_SSL_3_0)
	  send_packet(finished_packet("CLNT"));
	else if(version >= PROTOCOL_TLS_1_0)
	  send_packet(finished_packet("client finished"));

	if (context->heartbleed_probe &&
	    session->heartbeat_mode == HEARTBEAT_MODE_peer_allowed_to_send) {
	  // Probe for the Heartbleed vulnerability (CVE-2014-0160).
	  send_packet(heartbleed_packet());
	}
      }

      // Handshake hash is calculated for both directions above.
      handshake_messages = 0;

      return 1;			// We're done shaking hands
    }
  }
  return 0;
}
