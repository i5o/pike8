//! GtkFileSelection should be used to retrieve file or directory names
//! from the user. It will create a new dialog window containing a
//! directory list, and a file list corresponding to the current
//! working directory. The filesystem can be navigated using the
//! directory list, the drop-down history menu, or the TAB key can be
//! used to navigate using filename completion common in text based
//! editors such as emacs and jed.
//! 
//! The default filename can be set using set_filename() and the
//! selected filename retrieved using get_filename().
//! 
//! Use complete() to display files that match a given pattern. This
//! can be used for example, to show only *.txt files, or only files
//! beginning with gtk*.
//! 
//! Simple file operations; create directory, delete file, and rename
//! file, are available from buttons at the top of the dialog. These
//! can be hidden using hide_fileop_buttons() and shown again using
//! show_fileop_buttons().
//! 
//!@expr{ GTK1.FileSelection("File selector")@}
//!@xml{<image>../images/gtk1_fileselection.png</image>@}
//!
//! 
//!
//!

inherit GTK1.Window;

GTK1.FileSelection complete( string pattern );
//! Will attempt to match pattern to a valid filename in the current
//! directory. If a match can be made, the matched filename will appear
//! in the text entry field of the file selection dialog. If a partial
//! match can be made, the "Files" list will contain those file names
//! which have been partially matched.
//!
//!

protected GTK1.FileSelection create( string window_title );
//! Creates a new file selection dialog box. By default it will list
//! the files in the current working directory. Operation buttons
//! allowing the user to create a directory, delete files, and rename
//! files will also be present by default.
//!
//!

GTK1.Button get_cancel_button( );
//! The cancel button
//!
//!

GTK1.Clist get_dir_list( );
//! The list of directories
//!
//!

GTK1.Clist get_file_list( );
//! The list of files
//!
//!

string get_filename( );
//! Returns the currently entered filename as a string
//!
//!

GTK1.Button get_fileop_c_dir( );
//! The create directory button in the file operation button group
//!
//!

GTK1.Button get_fileop_del_file( );
//! The delete file button in the file operation button group
//!
//!

GTK1.Button get_fileop_ren_file( );
//! The rename file button in the file operation button group
//!
//!

GTK1.Button get_help_button( );
//! The help button
//!
//!

GTK1.OptionMenu get_history_pulldown( );
//! Used to create the drop-down directory histor
//!
//!

GTK1.Button get_ok_button( );
//! The ok button
//!
//!

GTK1.FileSelection hide_fileop_buttons( );
//! Hides the file operation buttons that normally appear at the top of
//! the dialog. Useful if you wish to create a custom file selector,
//! based on GTK1.FileSelection.
//!
//!

GTK1.FileSelection set_filename( string fname );
//! Sets a default path for the file requestor. If filename includes a
//! directory path, then the requestor will open with that path as its
//! current working directory.
//!
//!

GTK1.FileSelection show_fileop_buttons( );
//! Shows the file operation buttons, if they have previously been
//! hidden. The rest of the widgets in the dialog will be resized
//! accordingly.
//!
//!
