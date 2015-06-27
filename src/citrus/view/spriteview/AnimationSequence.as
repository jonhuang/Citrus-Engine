package citrus.view.spriteview 
{
	import flash.display.FrameLabel;
	import flash.display.IGraphicsData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import citrus.core.CitrusEngine;
	
	import org.osflash.signals.Signal;
	
	
	/**
	 * AnimationSequence.as wraps a flash MovieClip to manage different animations.
	 * The .fla used should have a specific format following the format of the "patch demo"
	 * https://github.com/alamboley/Citrus-Engine-Examples/blob/master/fla/patch_character-SpriteArt.fla
	 * 
	 * For each animation, have as many frames on the main timeline as needed for each:
	 * The animations should be playing along with the main timeline as AnimationSequence will control the playhead for pausing/resuming/looping.
	 * 
	 * animations should be put in sequence without any gaps.
	 * to define where each animation start and ends, spread a keyframe over each animation with a frame label.
	 * this label will be the animation name.
	 * 
	 * The MC already starts stopped (so you don't need to call stop() ).
	 * In fact you should not control the timeline yourself through actionscript in the fla, AnimationSequence will
	 * take care of looping animations that need looping, going back and forth or stopping as well as pause/resume.
	 */
	
	
	// JON: Creating a version of this where you can jump to a percent of an action. 
	// and you can play from that position too. 
	
	public class AnimationSequence extends Sprite
	{
		public static const HOLD:String = "HOLD"; // a very special animation
		public static const REVERSE_PREFIX:String = "!"; // indicates to play that animation backwards!
		
		protected var _ce:CitrusEngine;
		
		protected var _mc:MovieClip;
		protected var anims:Dictionary;
		
		protected var time:int = 0;
		
		protected var _currentAnim:AnimationSequenceData;
		protected var _currentFrame:int = 0;
		protected var _looping:Boolean = false;
		protected var _playing:Boolean = false;
		protected var _paused:Boolean = false;
		protected var _animChanged:Boolean = false;
		
		public var onAnimationComplete:Signal;
		
		/**
		 * if fpsRatio = .5, the animations will go 1/2 slower than the stage fps.
		 */
		public var fpsRatio:Number = 1; // jon-- changing this causes problems when the art changes!

		/**
		 * when set, animations start at the end and go to the beginning!
		 */
		public var backwards:Boolean = false; 
		
		protected var _frameHold:Boolean = false;
		protected var _frameHoldData:Vector.<IGraphicsData>;
		protected var _frameHolder:Sprite;
		
		public function AnimationSequence(mc:MovieClip) 
		{
			_ce = CitrusEngine.getInstance();
			_mc = mc;
			anims = new Dictionary();
			
			if (_mc.totalFrames != 1)
			{
				onAnimationComplete = new Signal(String);
				setupMCActions();
				_mc.gotoAndStop(0);
				_ce.stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			}
			
			addChild(_mc);
		}
		
		protected function handleEnterFrame(e:Event):void
		{
			if (_paused)
				return;
			
			if (_playing)
			{
				if (_frameHold) {
					MotionHold.draw(_frameHoldData, _frameHolder);
					// flagged complete every frame.
					
					if (!_looping) {
						handleAnimationComplete();
					}
				}
				else {
					
					var atEnd:Boolean = false;
					
					if(fpsRatio == 1 || (time%((1/fpsRatio)<<0) == 0)) {
						
						if (backwards) {
							_mc.prevFrame();
							atEnd = ((!_looping && _mc.currentFrame == _currentAnim.startFrame) 	// at the end
								||(_currentAnim.startFrame == _currentAnim.endFrame) 		// 1-frame animation
								||(_looping && _mc.currentFrame < _currentAnim.startFrame));
						}
						else {
							_mc.nextFrame();
							atEnd = ((!_looping && _mc.currentFrame == _currentAnim.endFrame) 	// at the end
								||(_currentAnim.startFrame == _currentAnim.endFrame) 		// 1-frame animation
								||(_looping && _mc.currentFrame > _currentAnim.endFrame));
						}
					}
					time++;
		
					if (atEnd) {
						handleAnimationComplete();	
					}
				}
				
			}
		}
		
		protected function handleAnimationComplete():void
		{
			onAnimationComplete.dispatch(_currentAnim.name);
			if (_looping && _playing)
				changeAnimation(_currentAnim.name, _looping);
			else
				_playing = false;
		}
		
		protected function setupMCActions():void
		{
			var name:String;
			var frame:int;
			var anim:FrameLabel;
			
			for each (anim in _mc.currentLabels)
			{
				name = anim.name;
				frame = anim.frame;
				
				if (name in anim)
					continue;
					
				anims[name] = new AnimationSequenceData(name, frame);
				
				if (!_currentAnim)
					_currentAnim = anims[name];
			}
			
			var previousAnimation:String;
			
			for each (anim in _mc.currentLabels)
			{
				if(previousAnimation)
					AnimationSequenceData(anims[previousAnimation]).endFrame = anim.frame-1;
				previousAnimation = anim.name;
			}
			AnimationSequenceData(anims[previousAnimation]).endFrame = _mc.totalFrames-1;
		}
		
		
		public function set frameHold(val:Boolean):void {
			_frameHold = val;
			
			if (val) {
				if (!_frameHolder) {
					_frameHolder = new Sprite();
					_frameHoldData = MotionHold.cloneGraphicsData(_mc.graphics.readGraphicsData());
					addChild(_frameHolder);
					removeChild(_mc);
				}
				
			}
			else {
				if (_frameHolder) {
					addChild(_mc);
					removeChild(_frameHolder);
					_frameHolder = null;
					_frameHoldData = null;
				}
			}
			
		}
		
		public function get frameHold():Boolean {
			return _frameHold;
		}
		
		public function pause():void
		{
			_paused = true;
			_ce.stage.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		public function resume():void
		{
			_paused = false;
			_ce.stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		// JON 
		public function jump(name:String, percent:Number):void {
			this.pause();
			if (name in anims) {
				_currentAnim = anims[name];
				_mc.gotoAndStop(_currentAnim.startFrame + (Math.floor(_currentAnim.endFrame - _currentAnim.startFrame)*percent));
			}
		}
		
		public function getAnimationLength(name:String):int {
			if (name in anims) {
				var query:AnimationSequenceData = anims[name];
				return (query.endFrame - query.startFrame);  // TODO fix one frame actions here? do a || 1?
			}
			else {
				throw new Error("AnimationSequence::GetAnimationLength(name): '" + name + "' not found");
			}
			return 0;
			
		}
		
		
		public function changeAnimation(name:String, loop:Boolean = false):void
		{
			_looping = loop;
			
			// special mode, backwards
			if (name.charAt(0) === REVERSE_PREFIX) {
				this.backwards = true;
				name = name.substr(1); // chop!
			}
			else {
				this.backwards = false;
			}
			
			// special mode, HOLD
			if (name == HOLD) {
				this.frameHold = true;
				_playing = true;
				return;
			}
			else {
				this.frameHold = false;
			}
			
			if (name in anims)
			{
				_currentAnim = anims[name];
				
				if (this.backwards) {
					_mc.gotoAndStop(_currentAnim.endFrame);
				}
				else {
					_mc.gotoAndStop(_currentAnim.startFrame);
				}
				_playing = true;
			}
		}
		
		public function hasAnimation(animation:String):Boolean
		{
			return !!anims[animation] 
				|| animation == HOLD 
				|| (!!anims[animation.slice(1)] && animation.charAt(0) == REVERSE_PREFIX);
		}
		
		public function destroy():void
		{
			_ce.stage.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			onAnimationComplete.removeAll();
			anims = null;
			removeChild(_mc);
		}
		
		public function get mc():MovieClip {
			return _mc;
		}
		
		
		
	}

}

internal class AnimationSequenceData 
{
	internal var startFrame:int;
	internal var endFrame:int;
	internal var name:String;
	public function AnimationSequenceData(name:String,startFrame:int = -1,endFrame:int = -1)
	{
		this.name = name;
		this.startFrame = startFrame;
		this.endFrame = endFrame;
	}
}