package eu.stefaner.relationbrowser {
	import eu.stefaner.relationbrowser.data.NodeData;
	import eu.stefaner.relationbrowser.layout.RadialLayout;
	import eu.stefaner.relationbrowser.layout.VisibilityFilter;
	import eu.stefaner.relationbrowser.ui.Edge;
	import eu.stefaner.relationbrowser.ui.Node;

	import flare.analytics.cluster.CommunityStructure;
	import flare.analytics.cluster.HierarchicalCluster;
	import flare.animate.TransitionEvent;
	import flare.animate.Transitioner;
	import flare.util.Vectors;
	import flare.vis.Visualization;
	import flare.vis.controls.ClickControl;
	import flare.vis.controls.HoverControl;
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.EdgeSprite;
	import flare.vis.events.SelectionEvent;
	import flare.vis.operator.Operator;

	import org.osflash.thunderbolt.Logger;

	import flash.events.Event;
	import flash.utils.Dictionary;

	public class RelationBrowser extends Visualization {
		// --------------------------------------
		// CONSTRUCTOR
		// --------------------------------------
		public var selectedNode : Node;
		private var _depth : uint = 2;
		public var layout : RadialLayout;
		public var visibilityOperator : VisibilityFilter;
		protected var clusterer : HierarchicalCluster;
		protected var transitioner : Transitioner = new Transitioner(1);
		protected var nodesByID : Dictionary = new Dictionary();
		protected var visibleNodes : DataList;
		protected var visibleEdges : DataList;
		public static const NODE_SELECTED : String = "NODE_SELECTED";
		public static const NODE_SELECTION_FINISHED : String = "NODE_SELECTION_FINISHED";
		public static const NODE_CLICKED : String = "NODE_CLICKED";
		public var showOuterEdges : Boolean = true;
		public var showInterConnections : Boolean = false;
		public var lastClickedNode : Node;
		public var maxItems : Number;
		public var maxItemCriterion : Array;

		/**
		 *@Constructor
		 */
		public function RelationBrowser() {
			super();
		}

		public function selectNodeByID(id : String) : void {
			var n : Node = nodesByID[id] as Node;
			if (!n) {
				throw new Error("could not select node by id: " + id);
			} else {
				selectNode(n);
			}
		}

		protected function initLayout() : void {
			visibilityOperator = new VisibilityFilter("visibleNodes", [], depth);
			operators.add(visibilityOperator);

			clusterer = new CommunityStructure();
			clusterer.group = "visibleNodes";
			operators.add(clusterer);

			layout = new RadialLayout(sortBy);
			operators.add(layout);
		}

		public var _nodeDefaults : Object;

		public function set nodeDefaults(nodeDefaults : Object) : void {
			data.nodes.setDefaults(nodeDefaults);
			data.nodes.setProperties(nodeDefaults);
			_nodeDefaults = nodeDefaults;
		}

		public function get nodeDefaults() : Object {
			return _nodeDefaults;
		}

		private var _edgeDefaults : Object;

		public function set edgeDefaults(edgeDefaults : Object) : void {
			data.edges.setDefaults(edgeDefaults);
			data.edges.setProperties(edgeDefaults);
			_edgeDefaults = edgeDefaults;
		}

		public function get edgeDefaults() : Object {
			return _edgeDefaults;
		}

		protected function initControls() : void {
			controls.add(new ClickControl(Node, 1, onNodeClick));
			controls.add(new HoverControl(Node, HoverControl.MOVE_AND_RETURN, onNodeRollOver, onNodeRollOut));
		}

		public function addOperator(o : Operator) : void {
			operators.add(o);
		}

		public function addOperators(a : Vector.<Operator>) : void {
			for each (var i:Operator in a) {
				addOperator(i);
			}
		}

		protected function onNodeClick(e : SelectionEvent) : void {
			trace("click " + e.node);
			var n : Node = e.node as Node;
			if (n != null) {
				n.onClick();
				lastClickedNode = n;
				dispatchEvent(new Event(NODE_CLICKED));
				selectNode(n);
			}
		}

		protected function onNodeRollOver(e : SelectionEvent) : void {
			trace("over " + e.cause.target);
			var n : Node = e.node as Node;
			if (n != null) {
				n.onRollOver();
			}
		}

		protected function onNodeRollOut(e : SelectionEvent) : void {
			trace("out " + e.node);
			var n : Node = e.node as Node;
			if (n != null) {
				n.onRollOut();
			}
		}

		public function selectNode(n : Node = null) : void {
			Logger.info("onNodeSelected " + n);

			if (n == selectedNode) {
				Logger.warn("RelationBrowser.selectNode: already selected, returning");
				return;
			}

			if (selectedNode != null) {
				selectedNode.selected = false;
			}

			if (n != null) {
				n.selected = true;
			} else {
				Logger.warn("RelationBrowser.selectNode: no selection");
			}

			selectedNode = n;
			updateDisplay();
			dispatchEvent(new Event(NODE_SELECTED));
		}

		public function updateDisplay(t : Transitioner = null) : Transitioner {
			Logger.info("updateSelection  " + selectedNode);
			if(!t) {
				transitioner = new Transitioner(1);
			}

			if (!transitioner.hasEventListener(TransitionEvent.END)) {
				transitioner.addEventListener(TransitionEvent.END, onTransitionEnd, false, 0, true);
			}

			if (selectedNode == null) {
				Logger.warn("RelationBrowser.updateSelection: no node selected");
				// how to handle generally?
				layout.enabled = false;
				clusterer.enabled = false;
				visibilityOperator.enabled = false;
			} else {
				layout.enabled = true;
				visibilityOperator.enabled = true;
				clusterer.enabled = true;
				layout.layoutRoot = selectedNode;
				visibilityOperator.focusNodes = Vectors.copyFromArray([selectedNode]);
			}

			preUpdate(transitioner);
			update(transitioner);
			postUpdate(transitioner);

			transitioner.play();

			return transitioner;
		}

		public function onTransitionEnd(event : TransitionEvent) : void {
			dispatchEvent(new Event(NODE_SELECTION_FINISHED));
		}

		public function preUpdate(t : Transitioner = null) : void {
			t = Transitioner.instance(t);
		}

		public function postUpdate(t : Transitioner = null) : void {
			t = Transitioner.instance(t);
		}

		public function addNode(o : NodeData, icon : Class = null) : Node {
			var n : Node = getNodeByID(o.id);
			if (n == null) {
				// no node yet for ID: create node
				n = nodesByID[o.id] = createNode(o, icon);
				data.nodes.applyDefaults(n);
				data.addNode(n);
			} else {
				// existing node: set new data
				n.data = o;
			}

			return n;
		}

		protected function createNode(data : NodeData, icon : Class = null) : Node {
			return new Node(data, icon);
		}

		public function getNodeByID(id : String) : Node {
			return nodesByID[id];
		}

		public function addEdge(fromID : String, toID : String, directed : Boolean = false, d : Object = null) : EdgeSprite {
			var node1 : Node = getNodeByID(fromID);
			var node2 : Node = getNodeByID(toID);

			var e : Edge = createEdge(node1, node2, directed);
			if (d != null) {
				e.data = d;
			}

			try {
				node1.addOutEdge(e);
				node2.addInEdge(e);
				data.addEdge(e);
				data.edges.applyDefaults(e);
			} catch (err : Error) {
				Logger.warn("Problem adding edge ", err.message, fromID, toID, directed, d);
			}
			return e;
		}

		protected function createEdge(node1 : Node, node2 : Node, directed : Boolean) : Edge {
			return new Edge(node1, node2, directed);
		}

		public function removeUnconnectedNodes() : void {
			for each (var n:Node in data.nodes) {
				if (n.degree == 0) {
					data.removeNode(n);
				}
			}
		}

		public function get depth() : uint {
			return _depth;
		}

		public function set depth(depth : uint) : void {
			_depth = depth;
			if (visibilityOperator) {
				visibilityOperator.distance = _depth;
			}
		}

		override public function get data() : Data {
			return super.data ? super.data : data = new Data();
		}

		override public function set data(data : Data) : void {
			super.data = data;
			visibleNodes = data.addGroup("visibleNodes");
			visibleEdges = data.addGroup("visibleEdges");
			initControls();
			initLayout();
		}

		private var _sortBy : Array;

		public function get sortBy() : Array {
			return _sortBy;
		}

		public function set sortBy(sortBy : Array) : void {
			_sortBy = sortBy;
			if (layout) {
				layout.sortBy = sortBy;
				updateDisplay();
			}
		}

		public function selectFirstNode() : void {
			selectNode(data.nodes[0]);
		}

		public function selectNodeByName(name : String) : void {
			for each (var n:Node in data.nodes) {
				if (n.data.label == name) {
					selectNode(n);
				}
			}
		}
	}
}