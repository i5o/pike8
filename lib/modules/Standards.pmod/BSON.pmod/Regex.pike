#pike __REAL_VERSION__

  constant BSONRegex = 1;

  string regex;
  string options;
  
  //!
  protected void create(string _regex, string _options)
  {
    regex = _regex;
    options = _options;
  }
  

