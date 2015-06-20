package citrus.view.spriteview
{
	import flash.display.GraphicsPath;
	import flash.display.GraphicsSolidFill;
	import flash.display.IGraphicsData;
	import flash.display.Sprite;
	
	public class MotionHold
	{
		public function MotionHold() {
			throw new Error("Static Function, do not instantiate");
		}
		
		protected static const THRESHOLD:Number = 3;
		protected static const TREMBLE:Number = .3;
		
		public static var TARGET_COLOR:int = -1
		
		// sort of a messy clone. Just makes new path data numbers, since the rest shouldn't change.
		public static function cloneGraphicsData(orig:Vector.<IGraphicsData>):Vector.<IGraphicsData> {
			var copy:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();
			var len:uint = orig.length;
			
			for (var i:int = 0; i<len; i++) {
				var p:GraphicsPath = orig[i] as GraphicsPath;
				if (p && p.data) {
					var pCopy:GraphicsPath = new GraphicsPath(p.commands, p.data.concat(), p.winding);
					copy.push(pCopy);
				}
				else {
					copy.push(orig[i]);
				}
			}
			return copy;
		}
		
		/**
		 * 
		 * 
		 * @targetFill: only apply motion hold to this color
		 */
		public static function draw(orig:Vector.<IGraphicsData>, copy:Sprite):void {
			
			var copyData:Vector.<IGraphicsData> = cloneGraphicsData(orig);
			var len:uint = copyData.length;
			
			var rand:Number = 0;

			var fillColor:uint; 
			
			for (var i:int = 0; i<len; i++) {
				
				
				// maybe it's a fill?
				var copyFill:GraphicsSolidFill = copyData[i] as GraphicsSolidFill;
				if (copyFill) {
					fillColor = copyFill.color;
					continue;
				}
				
				// we're not interested in things that are the wrong color.
				if (TARGET_COLOR >= 0 && fillColor !== TARGET_COLOR) {
					continue;
				}

				// okay, so it's a path
				var copyPath:GraphicsPath = copyData[i] as GraphicsPath;
				if (!copyPath) continue;
				
				var com:Vector.<int> = copyPath.commands;
				var comLen:uint = com.length;
				var path:Vector.<Number> = copyPath.data;
				var pathLen:uint = path.length;
				
				var lastX:Number = path[0];
				var lastY:Number = path[1];
				var lastDX:Number = 0;
				var lastDY:Number = 0;
				
				for (var c:int = 0, p:int = 0; c<comLen; c++) {
					
					// commands all seem to be 1,2,3
					var command:uint = com[c];
					
					if (command > 3 || command < 1) {
						throw new Error("Unexpected draw command! Tell jon to code some more!");
					}
					
					
					var x:Number = path[p];
					var y:Number = path[p+1];
					
					if (command == 1) {
						lastX = x;
						lastY = y;
					}
					// you want to scale the randomness by the length of the movement, unless it's a MOVETO command, in which 
					// case you want to reset it.
					var distX:Number = Math.sqrt(Math.abs(lastX-x));
					var distY:Number = Math.sqrt(Math.abs(lastY-y));
					var dx:Number = distX > THRESHOLD ? distX * (Math.random()-.5)*TREMBLE : lastDX;
					var dy:Number = distY > THRESHOLD ? distX * (Math.random()-.5)*TREMBLE : lastDY;
					
					// the adjustment point
					if (command == 3) {
						// ideally, we want the adjustment point to be propotionately the same.. hm.
						path[p++] += (lastDX + dx)/2;
						path[p++] += (lastDY + dy)/2;
					}
					
					// x coord
					path[p] += dx;
					lastX = x;
					
					// y coord
					path[p+1] += dy;
					lastY = y;
					
					p+=2;
					
					lastDX = dx;
					lastDY = dy;
					
				}
				
				// AH! the data numbers are pairs of XY coordinates. the X and Y should be treated differently..
				// or rather than randomize the positions, we should randomize the vector moves between them..
				
				// IMPORRRTANT!
				// AH! and the commands might have more than 2 parameters.. this is just a feed from it. hmm.
				// IN PARTICULAR you don't want to move the anchor points for commands.
				
				/*
				* 1,2,2,2,3,2,3,2,2,2,3,3,3,2,3,3,3,2,3,3,3,3,2,3,2,3,2,3,3,2,3,3,2,2,2,3,2,3,2,2,2,2,3,3,3,3,3,2,3,3,3,3,3,3,2,3,3,2,2,3,3,2,3
				* 
				CUBIC_CURVE_TO : int = 6
				[static] Specifies a drawing command that draws a curve from the current drawing position to the x- and y-coordinates specified in the data vector, using a 2 control points.
				GraphicsPathCommand
				CURVE_TO : int = 3
				Specifies a drawing command that draws a curve from the current drawing position to the x- and y-coordinates specified in the data vector, using a control point.
				This command produces the same effect as the Graphics.lineTo() method, and uses two points in the data vector control and anchor: (cx, cy, ax, ay 
				GraphicsPathCommand
				LINE_TO : int = 2
				[static] Specifies a drawing command that draws a line from the current drawing position to the x- and y-coordinates specified in the data vector.
				GraphicsPathCommand
				MOVE_TO : int = 1
				[static] Specifies a drawing command that moves the current drawing position to the x- and y-coordinates specified in the data vector.
				GraphicsPathCommand
				NO_OP : int = 0
				[static] Represents the default "do nothing" command.
				GraphicsPathCommand
				WIDE_LINE_TO : int = 5
				[static] Specifies a "line to" drawing command, but uses two sets of coordinates (four values) instead of one set.
				GraphicsPathCommand
				WIDE_MOVE_TO : int = 4
				[static] Specifies a "move to" drawing command, but uses two sets of coordinates (four values) instead of one set.
				*/
				
				copy.graphics.clear();
				copy.graphics.drawGraphicsData(copyData);
			}
		}
	}
}

