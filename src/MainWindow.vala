/*
 * MainWindow.vala
 *
 * Copyright 2013 Tony George <teejee@tony-pc>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

class MainWindow : Gtk.Window{

	private Gtk.Box vbox_main;

	//timers
	private uint tmr_init = 0;
	private int def_width = 650;
	private int def_height = 500;

	public MainWindow () {

		log_debug("MainWindow()");
		
		this.title = AppName + " v" + AppVersion;
        this.window_position = WindowPosition.CENTER;
        this.modal = true;
        this.set_default_size (def_width, def_height);
		//this.delete_event.connect(on_delete_event);
		this.icon = get_app_icon(16);

	    //vbox_main
        vbox_main = new Box (Orientation.VERTICAL, 0);
        vbox_main.margin = 0;
        add (vbox_main);

        //show_all();

		//tmr_init = Timeout.add(100, init_delayed);

		log_debug("MainWindow(): exit");
    }

    private bool init_delayed(){
		if (tmr_init > 0){
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		log_debug("MainWindow(): init_delayed()");

		
		log_debug("MainWindow(): init_delayed(): exit");
		
		return false;
	}

}
