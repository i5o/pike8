/*
 * Follow the PKCS#1 standard for padding and encryption.
 */

#pike __REAL_VERSION__
#pragma strict_types
#require constant(Crypto.Hash)

inherit Crypto.Sign;

//! Returns the string @expr{"RSA"@}.
string(8bit) name() { return "RSA"; }

class State {
  inherit ::this_program;

  protected string _sprintf(int t)
  {
    return t=='O' && sprintf("%O(%d)", this_program, n->size());
  }

  //
  // --- Variables and accessors
  //

  protected Gmp.mpz n;  /* modulo */
  protected Gmp.mpz e;  /* public exponent */
  protected Gmp.mpz d;  /* private exponent (if known) */
  protected int(31bit) size;

  /* Extra info associated with a private key. Not currently used. */
   
  protected Gmp.mpz p;
  protected Gmp.mpz q;

  protected function(int(0..):string(8bit)) random = .Random.random_string;

  Gmp.mpz get_n() { return n; } //! Returns the RSA modulo (n).
  Gmp.mpz get_e() { return e; } //! Returns the RSA public exponent (e).

  //! Returns the RSA private exponent (d), if known.
  Gmp.mpz get_d() { return d; }

  Gmp.mpz get_p() { return p; } //! Returns the first RSA prime (p), if known.
  Gmp.mpz get_q() { return q; } //! Returns the second RSA prime (q), if known.

  //! Sets the random function, used to generate keys and parameters, to
  //! the function @[r]. Default is @[Crypto.Random.random_string].
  this_program set_random(function(int(0..):string(8bit)) r)
  {
    random = r;
    return this;
  }

  //! Returns the string @expr{"RSA"@}.
  string(8bit) name() { return "RSA"; }

  //
  // --- Key methods
  //

  //! Can be initialized with a mapping with the elements n, e, d, p and
  //! q.
  protected void create(mapping(string(8bit):Gmp.mpz|int)|void params)
  {
    if(!params) return;
    if( params->n && params->e )
      set_public_key(params->n, params->e);
    if( params->d )
      set_private_key(params->d, ({ params->p, params->q, params->n }));
  }

  //! Sets the public key.
  //! @param modulo
  //!   The RSA modulo, often called n. This value needs to be >=12.
  //! @param pub
  //!   The public RSA exponent, often called e.
  this_program set_public_key(Gmp.mpz|int modulo, Gmp.mpz|int pub)
  {
    n = Gmp.mpz(modulo);
    e = Gmp.mpz(pub);
    size = n->size(256);
    if (size < 12)
      error( "Too small modulo.\n" );
    return this;
  }

  //! Compares the public key of this RSA object with another RSA
  //! object.
  int(0..1) public_key_equal(this_program rsa)
  {
    return n == rsa->get_n() && e == rsa->get_e();
  }

  //! Compares the keys of this RSA object with something other.
  protected int(0..1) _equal(mixed other)
  {
    if (!objectp(other) || (object_program(other) != object_program(this)) ||
	!public_key_equal([object(this_program)]other)) {
      return 0;
    }
    this_program rsa = [object(this_program)]other;
    return d == rsa->get_d();
  }

  //! Sets the private key.
  //! @param priv
  //!   The private RSA exponent, often called d.
  //! @param extra
  //!   @array
  //!     @elem Gmp.mpz|int 0
  //!       The first prime, often called p.
  //!     @elem Gmp.mpz|int 1
  //!       The second prime, often called q.
  //!   @endarray
  this_program set_private_key(Gmp.mpz|int priv, array(Gmp.mpz|int)|void extra)
  {
    d = Gmp.mpz(priv);
    if (extra)
    {
      p = Gmp.mpz(extra[0]);
      q = Gmp.mpz(extra[1]);
      n = [object(Gmp.mpz)](p*q);
      size = n->size(256);
    }
    return this;
  }

  //
  // --- Key generation
  //

#if constant(Nettle.rsa_generate_keypair)

  this_program generate_key(int bits, void|int e)
  {
    // While a smaller e is possible, and more efficient, using 0x10001
    // has become standard and is the only value supported by several
    // TLS implementations.
    if(!e)
      e = 0x10001;
    else
    {
      if(!(e&1)) error("e needs to be odd.\n");
      if(e<3) error("e is too small.\n");
      if(e->size()>bits) error("e has to be smaller in size than the key.\n");
    }

    if(bits<89) error("Too small key length.\n");

    array(Gmp.mpz) key = Nettle.rsa_generate_keypair(bits, e, random);
    if(!key) error("Error generating key.\n");
    [ n, d, p, q ] = key;
    this::e = Gmp.mpz(e);
    size = n->size(256);
    return this;
  }

#else

  // Generate a prime with @[bits] number of bits using random function
  // @[r].
  protected Gmp.mpz get_prime(int bits, function(int:string(8bit)) r)
  {
    int len = (bits + 7) / 8;
    int bit_to_set = 1 << ( (bits - 1) % 8);

    Gmp.mpz p;
  
    do {
      string(8bit) s = r(len);
      p = Gmp.mpz(sprintf("%c%s", (s[0] & (bit_to_set - 1))
			  | bit_to_set, s[1..]),
		  256)->next_prime();
    } while (p->size() > bits);

    return p;
  }

  //! Generate a valid RSA key pair with the size @[bits] using the
  //! random function set with @[set_random()]. The public exponent @[e]
  //! will be used, which defaults to 65537. Keys must be at least 89
  //! bits.
  this_program generate_key(int(128..) bits, void|int|Gmp.mpz e)
  {
    if (bits < 128)
      error( "Ridiculously small key.\n" );
    if( e )
    {
      if(!(e&1)) error("e needs to be odd.\n");
      if(e<3) error("e is too small.\n");
      if(e->size()>bits) error("e has to be smaller in size than the key.\n");
    }

    /* NB: When multiplying two n-bit integers,
     *     you're most likely to get an (2n - 1)-bit result.
     *     We therefore add an extra bit to s2.
     *
     * cf [bug 6620].
     */

    int s1 = bits / 2; /* Size of the first prime */
    int s2 = 1 + bits - s1;

    string(8bit) msg = "A" * (bits/8-3-8);

    do {
      Gmp.mpz p;
      Gmp.mpz q;
      Gmp.mpz mod;
      do {
	p = get_prime(s1, random);
	q = get_prime(s2, random);
	mod = [object(Gmp.mpz)](p * q);
      } while (mod->size() != bits);
      Gmp.mpz phi = [object(Gmp.mpz)](Gmp.mpz([object(Gmp.mpz)](p-1))*
				      Gmp.mpz([object(Gmp.mpz)](q-1)));

      array(Gmp.mpz) gs; /* gcd(pub, phi), and pub^-1 mod phi */

      // For a while it was thought that small exponents were a security
      // problem, but turned out was a padding problem. The exponent
      // 0x10001 has however become common practice, although a smaller
      // value would be more efficient.
      Gmp.mpz pub = Gmp.mpz(e || 0x10001);

      // For security reason we need to ensure no common denominator
      // between n and phi. We could create a different exponent, but
      // some Crypto packages are hard coded for 0x10001, so instead
      // we'll just start over.
      if ((gs = pub->gcdext2(phi))[0] != 1)
	continue;

      if (gs[1] < 0)
	gs[1] += phi;

      set_public_key(mod, pub);
      set_private_key(gs[1], ({ p, q }));

    } while (!raw_verify(msg, raw_sign(msg)));
    return this;
  }

#endif

  //
  // --- PKCS methods
  //

#define Sequence Standards.ASN1.Types.Sequence

  private class PKCS_RSA_class {
    Sequence signature_algorithm_id(.Hash);
    Sequence build_public_key(global::State);
  }
  private object(PKCS_RSA_class) PKCS_RSA =
    [object(PKCS_RSA_class)]Standards.PKCS["RSA"];

  //! Calls @[Standards.PKCS.RSA.signatue_algorithm_id] with the
  //! provided @[hash].
  Sequence pkcs_signature_algorithm_id(.Hash hash)
  {
    return PKCS_RSA->signature_algorithm_id(hash);
  }

  //! Calls @[Standards.PKCS.RSA.build_public_key] with this object as
  //! argument.
  Sequence pkcs_public_key()
  {
    return PKCS_RSA->build_public_key(this);
  }

#undef Sequence

  //! Signs the @[message] with a PKCS-1 signature using hash
  //! algorithm @[h]. This is equivalent to
  //! I2OSP(RSASP1(OS2IP(RSAES-PKCS1-V1_5-ENCODE(message)))) in PKCS#1
  //! v2.2.
  string(8bit) pkcs_sign(string(8bit) message, .Hash h)
  {
    string(8bit) di = Standards.PKCS.Signature.build_digestinfo(message, h);
    return [string(8bit)]sprintf("%*c", size, raw_sign(di));
  }

  //! Verify PKCS-1 signature @[sign] of message @[message] using hash
  //! algorithm @[h].
  int(0..1) pkcs_verify(string(8bit) message, .Hash h, string(8bit) sign)
  {
    if( sizeof(sign)!=size ) return 0;
    string(8bit) s = Standards.PKCS.Signature.build_digestinfo(message, h);
    return raw_verify(s, Gmp.mpz(sign, 256));
  }

  //
  // --- Encryption/decryption
  //

  //! Pads the message @[s] with @[rsa_pad] type 2, signs it and returns
  //! the signature as a byte string.
  //! @param r
  //!   Optional random function to be passed down to @[rsa_pad].
  string(8bit) encrypt(string(8bit) s, function(int:string(8bit))|void r)
  {
    return rsa_pad(s, 2, r)->powm(e, n)->digits(256);
  }

  //! Decrypt a message encrypted with @[encrypt].
  string(8bit) decrypt(string(8bit) s)
  {
    return rsa_unpad(Gmp.mpz(s, 256)->powm(d, n), 2);
  }

  //
  // --- Block cipher compatibility.
  //

  protected int encrypt_mode; // For block cipher compatible functions

  //! Sets the public key to @[key] and the mode to encryption.
  //! @seealso
  //!   @[set_decrypt_key], @[crypt]
  this_program set_encrypt_key(array(Gmp.mpz) key)
  {
    set_public_key(key[0], key[1]);
    encrypt_mode = 1;
    return this;
  }

  //! Sets the public key to @[key]and the mod to decryption.
  //! @seealso
  //!   @[set_encrypt_key], @[crypt]
  this_program set_decrypt_key(array(Gmp.mpz) key)
  {
    set_public_key(key[0], key[1]);
    set_private_key(key[2]);
    encrypt_mode = 0;
    return this;
  }

  //! Encrypt or decrypt depending on set mode.
  //! @seealso
  //!   @[set_encrypt_key], @[set_decrypt_key]
  string(8bit) crypt(string(8bit) s)
  {
    return (encrypt_mode ? encrypt(s) : decrypt(s));
  }

  //! Returns the crypto block size, or zero if not yet set.
  int block_size()
  {
    if(!size) return 0;
    // FIXME: This can be both zero and negative...
    return size - 3;
  }

  //! Returns the size of the key in terms of number of bits.
  int(0..) key_size() { return [int(0..)](size*8); }


  //
  //  --- Below are methods for RSA applied in other standards.
  //


  //! Pads the @[message] to the current block size with method
  //! @[type] and returns the result as an integer. This is equivalent
  //! to OS2IP(RSAES-PKCS1-V1_5-ENCODE(message)) in PKCS#1 v2.2.
  //! @param type
  //!   @int
  //!     @value 1
  //!       The message is padded with @expr{0xff@} bytes.
  //!     @value 2
  //!       The message is padded with random data, using the @[random]
  //!       function if provided. Otherwise the default random function
  //!       set in the object will be used.
  //!   @endint
  Gmp.mpz rsa_pad(string(8bit) message, int(1..2) type,
		  function(int(0..):string(8bit))|void random)
  {
    string(8bit) padding = "";

    // Padding length: RSA size - message size - 3 bytes; delimiter,
    // padding type and leading null (not explicitly coded, as Gmp.mpz
    // does the right thing anyway). Require at least 8 bytes of padding
    // as security margin.
    int len = size - 3 - sizeof(message);
    if (len < 8)
      error( "Block too large. (%d>%d)\n", sizeof(message), size-11 );

    switch(type)
    {
    case 1:
      padding = sprintf("%@c", allocate(len, 0xff));
      break;
    case 2:
      if( !random ) random = this::random;
      do {
	padding += random([int(0..)](len-sizeof(padding))) - "\0";
      }  while( sizeof(padding)<len );
      break;
    default:
      error( "Unknown type.\n" );
    }
    return Gmp.mpz(sprintf("%c", type) + padding + "\0" + message, 256);
  }

  //! Reverse the effect of @[rsa_pad].
  string(8bit) rsa_unpad(Gmp.mpz block, int type)
  {
    string(8bit) s = block->digits(256);

    // Content independent size information. Not timing sensitive.
    if( sizeof(s)!=(size-1) ) return 0;

    int i = Nettle.rsa_unpad(s, type);
    if( !i ) return 0;

    return s[i..];
  }

  //! Pads the @[digest] with @[rsa_pad] type 1 and signs it. This is
  //! equivalent to RSASP1(OS2IP(RSAES-PKCS1-V1_5-ENCODE(message))) in
  //! PKCS#1 v2.2.
  Gmp.mpz raw_sign(string(8bit) digest)
  {
    return rsa_pad(digest, 1, 0)->powm(d, n);
  }

  //! Verifies the @[digest] against the signature @[s], assuming pad
  //! type 1.
  //! @seealso
  //!   @[rsa_pad], @[raw_sign]
  int(0..1) raw_verify(string(8bit) digest, Gmp.mpz s)
  {
    return s->powm(e, n) == rsa_pad(digest, 1, 0);
  }
}

//! Calling `() will return a @[State] object.
protected State `()(mapping(string(8bit):Gmp.mpz|int)|void params)
{
  return State(params);
}
