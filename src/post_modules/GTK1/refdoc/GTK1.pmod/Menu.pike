//! A GTK1.Menu is a W(MenuShell) that implements a drop down menu
//! consisting of a list of W(MenuItem) objects which can be navigated
//! and activated by the user to perform application functions.
//! 
//! A GTK1.Menu is most commonly dropped down by activating a W(MenuItem)
//! in a W(MenuBar) or popped up by activating a W(MenuItem) in another
//! GTK1.Menu.
//! 
//! A GTK1.Menu can also be popped up by activating a
//! W(OptionMenu). Other composite widgets such as the W(Notebook) can
//! pop up a GTK1.Menu as well.
//! 
//! Applications can display a GTK1.Menu as a popup menu by calling the
//! popup() function. The example below shows how an application can
//! pop up a menu when the 3rd mouse button is pressed.
//! 
//! @pre{
//!   GTK1.Menu menu = create_menu();
//!   GTK1.Window window = create_window();
//!   window->signal_connect( "button_press_event", lambda(GTK1.Menu m,
//!                                                        GTK1.Window w,
//!                                                        mapping e ) {
//!             if( e->button == 3 )
//!              menu->popup();
//!          }, menu );
//! @}
//!
//!

inherit GTK1.MenuShell;

GTK1.Menu append( GTK1.Widget widget );
//! Adds a new W(MenuItem) to the end of the menu's item list.
//!
//!

GTK1.Menu attach_to_widget( GTK1.Widget widget );
//! Attach the menu to a widget
//!
//!

protected GTK1.Menu create( );
//! Create a new GTK1.Menu widget.
//!
//!

GTK1.Menu detach( );
//!  Detaches the menu from the widget to which it had been attached.
//!
//!

GTK1.Widget get_active( );
//! Returns the selected menu item from the menu.
//!  This is used by the W(OptionMenu).
//!
//!

GTK1.Widget get_attach_widget( );
//! Returns the W(Widget) that the menu is attached to.
//!
//!

int get_torn_off( );
//! return 1 if the menu is torn off.
//!
//!

GTK1.Menu insert( GTK1.Widget widget, int position );
//! Adds a new W(MenuItem) to the menu's item list at the position
//! indicated by position.
//!
//!

GTK1.Menu popdown( );
//! Removes the menu from the screen.
//!
//!

GTK1.Menu popup( int|void button_pressed_to_show_menu );
//! The default button is 3.
//!
//!

GTK1.Menu prepend( GTK1.Widget widget );
//! Adds a new W(MenuItem) to the start of the menu's item list.
//!
//!

GTK1.Menu reorder_child( GTK1.Widget menuitem, int pos );
//! Moves a W(MenuItem) to a new position within the GTK1.Menu.
//!
//!

GTK1.Menu reposition( );
//! Repositions the menu according to its position function.
//!
//!

GTK1.Menu set_accel_group( GTK1.AccelGroup accelerators );
//! Set the W(AccelGroup) which holds global accelerators for the menu.
//!
//!

GTK1.Menu set_active( int activep );
//! Selects the specified menu item within the menu. This is used by
//! the W(OptionMenu).
//!
//!

GTK1.Menu set_tearoff_state( int torn_off );
//! Changes the tearoff state of the menu. A menu is normally displayed
//! as drop down menu which persists as long as the menu is active. It
//! can also be displayed as a tearoff menu which persists until it is
//! closed or reattached.
//!
//!

GTK1.Menu set_title( string new_title );
//! Sets the title string for the menu. The title is displayed when the
//! menu is shown as a tearoff menu.
//!
//!
