
void main(int argc, array(string) argv)
{
  function write = Stdio.File(argv[2], "wct")->write;
  mapping classes = ([]);
  foreach( Stdio.read_file(argv[1])/"\n", string line )
  {
    sscanf( line, "%s#", line );
    if( !sizeof( line ) )
      continue;
    array data = line / ";";
    if( sizeof( data ) != 15 )
      continue;
    int c, cc;
    sscanf( data[0], "%x", c );
    sscanf( data[3], "%d", cc );
    if( cc )
      classes[c] = cc;
  }

  write( "static const struct canonical_cl _ca[] = {\n" );
  mapping top=([]);
  foreach( reverse(sort( indices( classes ) )), int c )
    write( "{%d,%d},\n", c, classes[c]);
  write( "};\n" );
}
