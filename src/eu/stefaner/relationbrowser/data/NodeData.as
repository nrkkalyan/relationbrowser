﻿package eu.stefaner.relationbrowser.data {	public  class NodeData {		public var id : String;		public var label : String;		public var type : String;
		public var props : Object;
		
		public function NodeData(id : String, o : Object = null , label : String = null, type : String = null) {			this.id = id;			this.props = o ? o : {};			this.label = label ? label : (o && o.name ? o.name : id);			this.type = type ? type : (o && o.type ? o.type : null);					}	}}