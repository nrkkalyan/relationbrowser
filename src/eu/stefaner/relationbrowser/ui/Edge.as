﻿package eu.stefaner.relationbrowser.ui {	import flare.animate.Transitioner;	import flare.vis.data.EdgeSprite;	import flare.vis.data.NodeSprite;	/**	 * @author mo	 */	public class Edge extends EdgeSprite {		public var weight : Number = 1;
		public var type : String = "";
		public var curved : Boolean;
		public function Edge(source : NodeSprite = null, target : NodeSprite = null, directed : Boolean = false) {			super(source, target, directed);		}		public function show(_t : Transitioner) : void {			_t.$(this).alpha = 1;			_t.$(this).visible = true;			visible = true;		}	}}