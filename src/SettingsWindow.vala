/*
 * OneClickSettingsDialog.vala
 *
 * Copyright 2015 Tony George <teejee2008@gmail.com>
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

public class SettingsWindow : Gtk.Window {

	private Gtk.Box vbox_main;
	private Gtk.CheckButton chk_custom_icon;
	private Gtk.Entry txt_tray_icon_path;
	private uint tmr_init = 0;
	
	public SettingsWindow(Gtk.Window? parent) {

		if (parent != null){
			set_transient_for(parent);
			window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		}
		else{
			window_position = Gtk.WindowPosition.CENTER;
		}
		
		set_modal(true);
		set_skip_taskbar_hint(true);
		set_skip_pager_hint(true);
		
		deletable = false;
		resizable = false;
		
		icon = get_app_icon(16,".svg");

		title = _("Settings");
		
		// get content area
		vbox_main = new Box (Orientation.VERTICAL, 0);
        vbox_main.spacing = 6;
		vbox_main.margin = 12;
        add (vbox_main);
		
		//vbox_main.margin_bottom = 12;
		vbox_main.set_size_request(400,400);

		// heading
		var label = new Label("<b>" + _("System Tray Icon") + "</b>");
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.margin_bottom = 6;
		vbox_main.add (label);
		
		init_option_custom_icon();
		
		create_actions();
		
        show_all();

		tmr_init = Timeout.add(100, init_delayed);

		log_debug("MainWindow(): exit");
    }

    private bool init_delayed(){
		if (tmr_init > 0){
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		log_debug("SettingsWindow(): init_delayed()");

		chk_custom_icon.active = App.use_custom_tray_icon;
		chk_custom_icon.toggled();
		
		log_debug("SettingsWindow(): init_delayed(): exit");
		
		return false;
	}

	private void init_option_custom_icon(){

		var chk = new Gtk.CheckButton.with_label(_("Use custom icon"));
		chk.active = App.use_custom_tray_icon;
		chk.margin_left = 6;
		vbox_main.add(chk);
		chk_custom_icon = chk;

		Box hbox = new Box (Gtk.Orientation.HORIZONTAL, 6);
		vbox_main.pack_start (hbox, false, true, 0);

		var entry = new Gtk.Entry();
		entry.hexpand = true;
		//entry.secondary_icon_stock = "gtk-open";
		entry.margin_left = 6;
		hbox.pack_start (entry, true, true, 0);
		txt_tray_icon_path = entry;
		
		if ((App.custom_tray_icon_path != null) && file_exists (App.custom_tray_icon_path)) {
			var path = App.custom_tray_icon_path;
			entry.text = path;
		}

		entry.changed.connect(() => {
			var path = txt_tray_icon_path.text;
			if (file_exists(path)){
				App.custom_tray_icon_path = path;
				App.disk_indicator.refresh_tray_icon();
			}
		});
		
		entry.icon_release.connect((p0, p1) => {
			select_icon_file();
		});

		// browse
		var button = new Gtk.Button.with_label (" " + _("Select") + " ");
		button.set_size_request(80, -1);
		button.set_tooltip_text(_("Select icon file"));
		hbox.pack_start (button, false, true, 0);
		var btn_browse_tray_icon = button;
		
		button.clicked.connect(select_icon_file);

		chk_custom_icon.toggled.connect(()=>{
			App.use_custom_tray_icon = chk_custom_icon.active;
			txt_tray_icon_path.sensitive = App.use_custom_tray_icon;
			btn_browse_tray_icon.sensitive = App.use_custom_tray_icon;
			App.disk_indicator.refresh_tray_icon();
		});
	}

	private void select_icon_file(){
		//chooser
		var chooser = new Gtk.FileChooserDialog(
			"Select Path",
			this,
			FileChooserAction.OPEN,
			"_Cancel",
			Gtk.ResponseType.CANCEL,
			"_Open",
			Gtk.ResponseType.ACCEPT
		);

		chooser.select_multiple = false;
		chooser.set_filename(App.custom_tray_icon_path);

		if (chooser.run() == Gtk.ResponseType.ACCEPT) {
			txt_tray_icon_path.text = chooser.get_filename();
		}

		chooser.destroy();
	}
	
	private void create_actions(){

		var label = new Gtk.Label("");
		label.vexpand = true;
		vbox_main.add(label);
		
		var hbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
		hbox.margin = 0;
		hbox.margin_top = 6;
        vbox_main.add(hbox);

		Gtk.SizeGroup size_group = null;
		
		// close
		
		var img = new Image.from_stock("gtk-close", Gtk.IconSize.BUTTON);
		var btn_close = add_button(hbox, _("Close"), "", ref size_group, img);
		//hbox.set_child_packing(btn_close, false, true, 6, Gtk.PackType.END);
		
        btn_close.clicked.connect(()=>{
			App.save_app_config();
			App.disk_indicator.refresh_tray_icon();
			this.destroy();
		});
	}
}


