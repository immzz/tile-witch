package  {
	
	public class Map {
		public static var BLOCK_SIZE:Number = 32;
		public var n_block_x:Number;
		public var n_block_y:Number;
		public var layers:Array;
		private var next_layer_index = 0;
		
		
		public function Map(nBlocksX:Number,nBlocksY:Number) {
			n_block_x = nBlocksX;
			n_block_y = nBlocksY;
			var collision_layer:Layer = new Layer(next_layer_index,n_block_x,n_block_y,true);
			next_layer_index++;
			layers = new Array();
			layers.unshift(collision_layer);
		}
		
		public function createLayer():Layer{
			return createLayerAt(0);
		}
		
		public function createLayerAt(index:Number):Layer{
			trace("CREATE LAYER AT "+index);
			var layer:Layer = new Layer(next_layer_index,n_block_x,n_block_y,false);
			next_layer_index++;
			for(var i:Number=layers.length - 1;i >= index;i--){
				layers[i+1] = layers[i];
			}
			layers[index] = layer;
			return layer;
		}
		
		public function removeLayerAt(index:Number):Layer{
			if(index == layers.length - 1){
				return null;
			}
			var removed_layer:Layer = layers[index];
			layers.splice(index,1);
			return removed_layer;
		}
		
		public function getNumLayers():Number{
			return layers.length;
		}
		
		public function swapLayers(index1:Number,index2:Number):Boolean{
			if(index1 >= layers.length - 1 || index2 >= layers.length - 1 || index1 < 0 || index2 < 0){
				return false;
			}
			var temp:Layer = layers[index1];
			layers[index1] = layers[index2];
			layers[index2] = temp;
			return true;
		}
		
		public function moveUpLayer(index:Number){
			return swapLayers(index,index + 1);
		}
		
		public function moveDownLayer(index:Number){
			return swapLayers(index,index - 1);
		}
		
		
		
		/*
		Collision layer lies on top of all layers
		*/
		public function getCollisionLayer():Layer{
			return layers[layers.length - 1];
		}
		
		public function getLayerAt(index:Number):Layer{
			return layers[index];
		}
		
		public function addTile(tile:Tile,layer:Layer,block_x:Number,block_y:Number):Boolean{
			return layer.addTile(tile,block_x,block_y);
		}
		

	}
	
}
