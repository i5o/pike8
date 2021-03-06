//! A fixed container is a container that keeps it's children at fixed
//! locations and give them fixed sizes, both given in pixels.
//! 
//!  Example:
//!@expr{ GTK1.Fixed()->put(GTK1.Label("100,100"), 100, 100)->put(GTK1.Label("0,0"), 0, 0)->set_usize(150,115)@}
//!@xml{<image>../images/gtk1_fixed.png</image>@}
//!
//! 
//!
//!

inherit GTK1.Container;

protected GTK1.Fixed create( );
//! Create a new fixed widget
//!
//!

GTK1.Fixed move( GTK1.Widget widget, int new_xpos, int new_ypos );
//! Move the widget to new_xpos,new_ypos from it's old location.
//!
//!

GTK1.Fixed put( GTK1.Widget widget, int x, int y );
//! Place the widget at xpos,ypos.
//!
//!
