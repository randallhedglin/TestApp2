package com.wb.software
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public final class TestApp extends WBEngine
	{
		// engine constants
		private const APP_TITLE      :String  = "Test App";
		private const LONGEST_SIDE   :int     = 640;
		private const ORIENTATION    :int     = ORIENT_LANDSCAPE;
		private const BASE_ASPECT    :Number  = 4 / 3;
		private const EXT_ASPECT     :Number  = 16 / 9;
		private const BKG_COLOR      :uint    = 0x000000; // 0xRRGGBB
		private const MAX_SHADERS    :int     = 0;
		private const MAX_BUFFERS    :int     = 0;
		private const MAX_TEXTURES   :int     = 10;
		private const MAX_VIEWS      :int     = 10;
		private const MAX_SOUNDS     :int     = 0;
		private const MAX_MP3S       :int     = 0;
		private const MAX_TOUCHES    :int     = 4;

		// test mode flag
		private var TEST_MODE :Boolean = false;
		
		// test mode objects
		private var m_testMainTex    :int          = -1;
		private var m_testMainView   :int          = -1;
		private var m_testClampTex1  :int          = -1;
		private var m_testClampTex2  :int          = -1;
		private var m_testClampView1 :int          = -1;
		private var m_testClampView2 :int          = -1;
		private var m_testTouchTex   :Vector.<int> = null;
		private var m_testTouchView  :Vector.<int> = null;
		private var m_testLastPause  :Date         = null;
		private var m_testLastResume :Date         = null;
		
		// misc. flags
		private var m_firstUpdate  :Boolean = true;
		private var m_warningShown :Boolean = false;
		
		// default constructor
		public function TestApp(sprite         :Sprite,
								messenger      :WBMessenger,
								osFlag         :int,
								renderWhenIdle :Boolean,
								launchImg      :Bitmap,
								testMode       :Boolean)
		{
			// defer to superclass
			super(sprite,
				  messenger,
				  osFlag,
				  renderWhenIdle,
				  launchImg,
				  APP_TITLE,
				  LONGEST_SIDE,
				  ORIENTATION,
				  BASE_ASPECT,
				  EXT_ASPECT,
				  BKG_COLOR,
				  MAX_SHADERS,
				  MAX_BUFFERS,
				  MAX_TEXTURES,
				  MAX_VIEWS,
				  MAX_SOUNDS,
				  MAX_MP3S,
				  MAX_TOUCHES);

			// copy test mode flag
			TEST_MODE = testMode;
		}
	
		// appAndroidBackKey() -- user has pushed Android back key
		override protected function appAndroidBackKey() :Boolean
		{
			// check warning flag
			if(!m_warningShown)
			{
				// show message
				messageBox("Press again to close!");
				
				// set warning flag
				m_warningShown = true;
				
				// handled
				return(true);
			}
				
			// she's all yours!
			return(false);
		}
		
		// appInit() -- perform initialization
		override protected function appInit() :void
		{
			// check mode
			if(TEST_MODE)
			{
				// enable graphics error checking
				enableGraphicsErrors();
				
				// set starting point for shared data
				if(!m_shared.data.testCountFlag)
				{
					m_shared.data.testCount     = 0;
					m_shared.data.testCountFlag = true;
				}
				
				// init test mode objects
				initTestMode();
			}
			else
			{
				// create launch image view
				viewAddLaunchImage();
				
				// enable error checking (remove from final!)
				enableGraphicsErrors();
	
				// track fps & memory
				viewAddFpsDisplay();
				viewAddMemoryDisplay();
			}
		}
		
		// appPause() -- handle loss of focus
		override protected function appPause() :void
		{
			// check mode
			if(TEST_MODE)
			{
				// save pause point
				savePausePoint();
				
				// update test mode views
				updateTestModeViews();
				
				// force loss of context
				testLossOfContext();
			}
		}
		
		// appRender() -- handle app-specific rendering **time-critical
		override protected function appRender() :void
		{
			// check mode
			if(TEST_MODE)
			{
				// update test mode views (must indicate first update)
				updateTestModeViews(m_firstUpdate);
				
				// reset first-update flag
				m_firstUpdate = false;
			}
		}
		
		// appResume() -- handle return of focus
		override protected function appResume() :void
		{
			// check mode
			if(TEST_MODE)
			{
				// force loss of context
				testLossOfContext();
			
				// save resume point
				saveResumePoint();
			}
		}

		// appUpdate() -- per-frame update **time-critical
		override protected function appUpdate() :void
		{
			// check mode
			if(TEST_MODE)
			{
				// increment shared data
				m_shared.data.testCount++;
			}
		}
		
		// drawCircleToBitmapData() -- add circle to bitmap data
		private function drawCircleToBitmapData(bmpData :BitmapData,
												  x       :int,
												  y       :int,
												  radius  :int,
												  color   :uint) :void
		{
			// draw circle
			for(var t :Number = 0; t <= Math.PI * 2; t += 1/(radius * 4))
				bmpData.setPixel32(Math.round(radius * Math.cos(t) + x) as int,
								   Math.round(radius * Math.sin(t) + y) as int,
								   color);
		}
		
		// drawLineToBitmapData() -- helper functoin to draw line to bitmap data (does not work with all lines!)
		private function drawLineToBitmapData(bmpData :BitmapData,
												x1      :int,
												y1      :int,
												x2      :int,
												y2      :int,
												color   :uint) :void
		{
			// counters
			var x :int;
			var y :int;
			
			// temporary value
			var temp :int;
			
			// check special cases
			if(x1 == x2) // vertical
			{
				// swap y values if needed
				if(y1 > y2)
					temp = y1, y1 = y2, y2 = temp;
				
				// draw line
				for(y = y1; y <= y2; y++)
					bmpData.setPixel32(x1, y, color);
			}
			else if(y1 == y2) // horizontal
			{
				// swap x values if needed
				if(x1 > x2)
					temp = x1, x1 = x2, x2 = temp;
				
				// draw line
				for(x = x1; x <= x2; x++)
					bmpData.setPixel32(x, y1, color);
			}
			else // slope between -1 and 1
			{
				// swap x values if needed
				if(x1 > x2)
					temp = x1, x1 = x2, x2 = temp;
				
				// compute deltas
				var dx :int = x2 - x1;
				var dy :int = y2 - y1;
				
				// draw line
				for(x = x1; x <= x2; x++)
				{
					// compute y
					y = y1 + dy * (x - x1) / dx;
					
					// set pixel
					bmpData.setPixel32(x, y, color);
				}
			}
		}
		
		// drawRectToBitmapData() -- helper function draw rectangle to bitmap data
		private function drawRectToBitmapData(bmpData :BitmapData,
												x       :int,
												y       :int,
												width   :int,
												height  :int,
												color   :uint) :void
		{
			// use debug function
			debugRectToBitmapData(bmpData, x, y, width, height, color);
		}
		
		// drawTestInfoToBitmapData() -- add test info box to bitmap data
		private function drawTestInfoToBitmapData(bmpData  :BitmapData,
													scale    :int,
													hideInfo :Boolean) :void
		{
			// available text area
			const textNumH :int = 27;
			const textNumV :int = 8;
			
			// compute text size
			var textWidth  :int = ((textNumH * 6) - 1) * scale; 
			var textHeight :int = ((textNumV * 8) - 3) * scale;
			
			// compute box size
			var boxWidth  :int = textWidth  + 16;
			var boxHeight :int = textHeight + 16;
			
			// compute box origin
			var boxX :int = Math.round((m_extWidth  / 2) - (boxWidth  / 2));
			var boxY :int = Math.round((m_extHeight / 2) - (boxHeight / 2));
			
			// compute text origin
			var textX :int = boxX + 8;
			var textY :int = boxY + 8;
			
			// draw box & border
			drawRectToBitmapData(bmpData, boxX, boxY, boxWidth, boxHeight, 0xFF002010);
			drawLineToBitmapData(bmpData, boxX + 2, boxY + 2, boxX + boxWidth - 3, boxY + 2, 0xFF004020);
			drawLineToBitmapData(bmpData, boxX + 2, boxY + boxHeight - 3, boxX + boxWidth - 3, boxY + boxHeight - 3, 0xFF004020);
			drawLineToBitmapData(bmpData, boxX + 2, boxY + 2, boxX + 2, boxY + boxHeight - 3, 0xFF004020);
			drawLineToBitmapData(bmpData, boxX + boxWidth - 3, boxY + 2, boxX + boxWidth - 3, boxY + boxHeight - 3, 0xFF004020);
			
			// check hide-info flag
			if(!hideInfo)
			{
				// os flag
				var osFlag :String;
				
				// set os flag
				switch(m_osFlag)
				{
					case(OSFLAG_ANDROID): osFlag = "ANDROID"; break;
					case(OSFLAG_IOS):     osFlag = "IOS";     break;
					case(OSFLAG_MACOSX):  osFlag = "MACOSX";  break;
					case(OSFLAG_WINDOWS): osFlag = "WINDOWS"; break;
					case(OSFLAG_BROWSER): osFlag = "BROWSER"; break;
					default:              osFlag = "UNDEF";   break;
				}
				
				// time data
				var hours        :Number;
				var am           :Boolean;
				var minutes      :Number;
				var seconds      :Number;
				var milliseconds :Number;
				
				// pause/resume times
				var lastPause  :String = "";
				var lastResume :String = "";
				
				// check last pause
				if(m_testLastPause)
				{
					// get pause time data
					hours        = (m_testLastPause.hours == 0) ? 12 : ((m_testLastPause.hours > 12) ? (m_testLastPause.hours - 12) : m_testLastPause.hours);
					am           = (m_testLastPause.hours < 12) ? true : false;
					minutes      = m_testLastPause.minutes;
					seconds      = m_testLastPause.seconds;
					milliseconds = m_testLastPause.milliseconds;
					
					// create pause time string
					lastPause = ((hours < 10) ? "0" + hours : hours) + ":" +
								((minutes < 10) ? "0" + minutes : minutes) + ":" +				
								((seconds < 10) ? "0" + seconds : seconds) + "." +				
								((milliseconds < 10) ? "00" + milliseconds : ((milliseconds < 100) ? "0" + milliseconds : milliseconds)) + " " +
								(am ? "am" : "pm");
				}
				
				// check last resume
				if(m_testLastResume)
				{
					// get resume time data
					hours        = (m_testLastResume.hours == 0) ? 12 : ((m_testLastResume.hours > 12) ? (m_testLastResume.hours - 12) : m_testLastResume.hours);
					am           = (m_testLastResume.hours < 12) ? true : false;
					minutes      = m_testLastResume.minutes;
					seconds      = m_testLastResume.seconds;
					milliseconds = m_testLastResume.milliseconds;
					
					// craete resume time string
					lastResume = ((hours < 10) ? "0" + hours : hours) + ":" +
								 ((minutes < 10) ? "0" + minutes : minutes) + ":" +				
								 ((seconds < 10) ? "0" + seconds : seconds) + "." +				
								 ((milliseconds < 10) ? "00" + milliseconds : ((milliseconds < 100) ? "0" + milliseconds : milliseconds)) + " " +
								 (am ? "am" : "pm");
				}
				
				// output test data
				drawTextToBitmapData(bmpData, "osFlag: " + osFlag, textX, textY + (0 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "goingNative: " + (m_goingNative ? "YES" : "NO"), textX, textY + (1 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "maxDisplayRes: " + m_maxDisplayRes, textX, textY + (2 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "stage: " + m_stageWidth + " x " + m_stageHeight, textX, textY + (3 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "sharedData: " + m_shared.data.testCount, textX, textY + (4 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "appActive: " + (m_appActive ? "YES" : "NO"), textX, textY + (5 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "lastPause: " + lastPause, textX, textY + (6 * scale * 8), scale);
				drawTextToBitmapData(bmpData, "lastResume: " + lastResume, textX, textY + (7 * scale * 8), scale);
				
				// save shared data
				saveSharedData();
			}
		}
		
		// drawTextToBitmapData() -- add simple text to bitmap data (useful for debugging; preface with ~ to right/bottom-justify)
		private function drawTextToBitmapData(bmpData :BitmapData,
												text    :String,
												x       :int,
												y       :int,
												scale   :int  = 1,
												color   :uint = 0xFFFFFFFF) :void
		{
			// use debug function
			debugTextToBitmapData(bmpData, text, x, y, scale, color);
		}

		// initTestMode() -- initialize objects needed for test mode
		private function initTestMode() :void
		{
			// add launch image
			viewAddLaunchImage();
			
			// counter
			var c :int;
			
			// create textures
			m_testMainTex   = textureAdd(nextGreaterPO2(m_extWidth), nextGreaterPO2(m_extHeight), false);
			m_testClampTex1 = textureAdd(64, 64);
			m_testClampTex2 = textureAdd(64, 64);
			
			// create touch texture array
			m_testTouchTex = new Vector.<int>(m_maxTouches, true);

			// create touch textures
			for(c = 0; c < m_maxTouches; c++)
				m_testTouchTex[c] = textureAdd(128, 128);
			
			// create views
			m_testMainView   = viewAddFromTextureInv(m_testMainTex);
			m_testClampView1 = viewAddFromTextureInv(m_testClampTex1);
			m_testClampView2 = viewAddFromTextureInv(m_testClampTex2)
			
			// create touch view array
			m_testTouchView = new Vector.<int>(m_maxTouches, true);
			
			// create touch views
			for(c = 0; c < m_maxTouches; c++)
				m_testTouchView[c] = viewAddFromTextureInv(m_testTouchTex[c]);
			
			// add fps & memory trackers
			viewAddFpsDisplay();
			viewAddMemoryDisplay();
			
			// test using max quality & anti-aliasing
			setStageQuality(QUALITY_BEST);
			setAntiAliasLevel(ANTIALIAS_MAX);
		}

		// savePausePoint() -- save time of most recent pause
		private function savePausePoint() :void
		{
			// save it
			m_testLastPause = new Date();
		}
		
		// saveResumePoint() -- save time of most recent resume
		private function saveResumePoint() :void
		{
			// save it
			m_testLastResume = new Date();
		}

		// updateTestModeViews() -- update bitmaps & views being used for test mode
		private function updateTestModeViews(firstUpdate :Boolean = false) :void
		{
			// after first update, hide launch image
			if(!firstUpdate)
				hideLaunchImageView();

			// set true to hide text info (for making launch image)
			const hideInfo :Boolean = false;
			
			// bitmap data (working)
			var bmpData :BitmapData = null;
			
			// counter
			var c :int;
			
			// grid size
			var gridSize :Number;
			
			// gridline data
			var numH :Number;
			var numV :Number;
			var ofsH :Number;
			var ofsV :Number;
			
			// get main texture
			bmpData = viewGetBitmapData(m_testMainView);
			
			// check orientation (default to landscape)
			if(m_orientation == ORIENT_PORTRAIT)
			{
				// compute grid size
				gridSize = m_auxHeight / 2;
				
				// clip to reasonable minimum
				if(gridSize < 50)
					gridSize = 50;
				
				// compute number of gridlines
				numH = Math.round(m_baseHeight / gridSize); 
				numV = Math.round(m_baseWidth  / gridSize);
				
				// compute grindline offsets
				ofsH = m_baseHeight / numH;
				ofsV = m_baseWidth  / numV;
				
				// draw aux background
				drawRectToBitmapData(bmpData, 0, 0, m_extWidth - 1, m_extHeight - 1, 0xFF001020);
				
				// draw aux gridlines (horizontal)
				drawLineToBitmapData(bmpData, 0, gridSize, m_extWidth - 1, gridSize, 0xFF002A55);
				drawLineToBitmapData(bmpData, 0, m_extHeight - gridSize - 1, m_extWidth - 1, m_extHeight - gridSize - 1, 0xFF002A55);
				
				// draw aux gridlines (vertical)
				for(c = 1; c < numV; c++)
					drawLineToBitmapData(bmpData, ofsV * c, 0, ofsV * c, m_extHeight - 1, 0xFF002A55);
				
				// draw aux border
				drawLineToBitmapData(bmpData, 0, 0, m_extWidth - 1, 0, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, 0, m_extHeight - 1, m_extWidth - 1, m_extHeight - 1, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, 0, 0, 0, m_extHeight - 1, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, m_extWidth - 1, 0, m_extWidth - 1, m_extHeight - 1, 0xFF0055AA);
				
				// draw aux coordinates
				if(!hideInfo)
				{
					drawTextToBitmapData(bmpData, m_extX + "," + m_extY, 3, 3);
					drawTextToBitmapData(bmpData, "~" + (m_baseWidth - 1) + "," + (m_baseHeight + m_auxHeight - 1), m_extWidth - 3, m_extHeight - 3);
				}

				// draw main background
				drawRectToBitmapData(bmpData, 0, m_auxHeight, m_baseWidth, m_baseHeight, 0xFF001530);
				
				// draw main gridlines (horizontal)
				for(c = 1; c < numH; c++)
					drawLineToBitmapData(bmpData, 0, m_auxHeight + ofsH * c, m_baseWidth - 1, m_auxHeight + ofsH * c, 0xFF004080);
				
				// draw main gridlines (vertical)
				for(c = 1; c < numV; c++)
					drawLineToBitmapData(bmpData, ofsV * c, m_auxHeight, ofsV * c, m_auxHeight + m_baseHeight - 1, 0xFF004080);
				
				// draw main border
				drawLineToBitmapData(bmpData, 0, m_auxHeight, m_baseWidth - 1, m_auxHeight, 0xFF0080FF);
				drawLineToBitmapData(bmpData, 0, m_auxHeight + m_baseHeight - 1, m_baseWidth - 1, m_auxHeight + m_baseHeight - 1, 0xFF0080FF);
				drawLineToBitmapData(bmpData, 0, m_auxHeight, 0, m_auxHeight + m_baseHeight - 1, 0xFF0080FF);
				drawLineToBitmapData(bmpData, m_baseWidth - 1, m_auxHeight, m_baseWidth - 1, m_auxHeight + m_baseHeight - 1, 0xFF0080FF);
				
				// draw main coordinates
				if(!hideInfo)
				{
					drawTextToBitmapData(bmpData, m_baseX + "," + m_baseY, 3, m_auxHeight + 3);
					drawTextToBitmapData(bmpData, "~" + (m_baseWidth - 1) + "," + (m_baseHeight - 1), m_baseWidth - 3, m_auxHeight + m_baseHeight - 3);
				}
			}
			else
			{
				// compute grid size
				gridSize = m_auxWidth / 2;
				
				// clip to reasonable minimum
				if(gridSize < 50)
					gridSize = 50;
				
				// compute number of gridlines
				numH = Math.round(m_baseHeight / gridSize); 
				numV = Math.round(m_baseWidth  / gridSize);
				
				// compute grindline offsets
				ofsH = m_baseHeight / numH;
				ofsV = m_baseWidth  / numV;
				
				// draw aux background
				drawRectToBitmapData(bmpData, 0, 0, m_extWidth - 1, m_extHeight - 1, 0xFF001020);
				
				// draw aux gridlines (horizontal)
				for(c = 1; c < numH; c++)
					drawLineToBitmapData(bmpData, 0, ofsH * c, m_extWidth - 1, ofsH * c, 0xFF002A55);
				
				// draw aux gridlines (vertical)
				drawLineToBitmapData(bmpData, gridSize, 0, gridSize, m_extHeight - 1, 0xFF002A55);
				drawLineToBitmapData(bmpData, m_extWidth - gridSize - 1, 0, m_extWidth - gridSize - 1, m_extHeight - 1, 0xFF002A55);
				
				// draw aux border
				drawLineToBitmapData(bmpData, 0, 0, m_extWidth - 1, 0, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, 0, m_extHeight - 1, m_extWidth - 1, m_extHeight - 1, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, 0, 0, 0, m_extHeight - 1, 0xFF0055AA); 
				drawLineToBitmapData(bmpData, m_extWidth - 1, 0, m_extWidth - 1, m_extHeight - 1, 0xFF0055AA);
				
				// draw aux coordinates
				if(!hideInfo)
				{
					drawTextToBitmapData(bmpData, m_extX + "," + m_extY, 3, 3);
					drawTextToBitmapData(bmpData, "~" + (m_baseWidth + m_auxWidth - 1) + "," + (m_baseHeight - 1), m_extWidth - 3, m_extHeight - 3);
				}

				// draw main background
				drawRectToBitmapData(bmpData, m_auxWidth, 0, m_baseWidth, m_baseHeight, 0xFF001530);
				
				// draw main gridlines (horizontal)
				for(c = 1; c < numH; c++)
					drawLineToBitmapData(bmpData, m_auxWidth, ofsH * c, m_auxWidth + m_baseWidth - 1, ofsH * c, 0xFF004080);
				
				// draw main gridlines (vertical)
				for(c = 1; c < numV; c++)
					drawLineToBitmapData(bmpData, m_auxWidth + ofsV * c, 0, m_auxWidth + ofsV * c, m_baseHeight - 1, 0xFF004080);
				
				// draw main border
				drawLineToBitmapData(bmpData, m_auxWidth, 0, m_auxWidth + m_baseWidth - 1, 0, 0xFF0080FF);
				drawLineToBitmapData(bmpData, m_auxWidth, m_baseHeight - 1, m_auxWidth + m_baseWidth - 1, m_baseHeight - 1, 0xFF0080FF);
				drawLineToBitmapData(bmpData, m_auxWidth, 0, m_auxWidth, m_baseHeight - 1, 0xFF0080FF);
				drawLineToBitmapData(bmpData, m_auxWidth + m_baseWidth - 1, 0, m_auxWidth + m_baseWidth - 1, m_baseHeight - 1, 0xFF0080FF);
				
				// draw main coordinates
				if(!hideInfo)
				{
					drawTextToBitmapData(bmpData, m_baseX + "," + m_baseY, m_auxWidth + 3, 3);
					drawTextToBitmapData(bmpData, "~" + (m_baseWidth - 1) + "," + (m_baseHeight - 1), m_auxWidth + m_baseWidth - 3, m_baseHeight - 3);
				}
			}
			
			// render test info
			drawTestInfoToBitmapData(bmpData, 2, hideInfo);
			
			// reupload main texture
			viewSaveBitmapData(m_testMainView);
			
			// set main view position & make visible
			viewSetPosition(m_testMainView, m_extX, m_extY);
			viewSetVisible (m_testMainView, true);
			
			// render clamp markers if not hiding
			if(!hideInfo)
			{
				// update clamp texture #1
				bmpData = viewGetBitmapData(m_testClampView1);
				drawRectToBitmapData(bmpData, 0, 0, 64, 64, 0x00000000);
				drawLineToBitmapData(bmpData, 0, 0, 0, 63, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 0, 63, 63, 63, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 0, 0, 63, 63, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 0, 1, 62, 63, 0xFF00FFFF);
				bmpData.floodFill(1, 62, 0x80008080);
				drawTextToBitmapData(bmpData, m_leftEdge + "," + (m_bottomEdge - 1), 3, 56);
				viewSaveBitmapData(m_testClampView1);
				
				// set clamp view position #1
				viewSetPosition(m_testClampView1,
								m_leftEdge,
								m_bottomEdge - viewGetBaseHeight(m_testClampView1));
				
				// update clamp texture #2
				bmpData = viewGetBitmapData(m_testClampView2);
				drawRectToBitmapData(bmpData, 0, 0, 64, 64, 0x00000000);
				drawLineToBitmapData(bmpData, 0, 0, 63, 0, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 0, 0, 63, 63, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 63, 0, 63, 63, 0xFF00FFFF);
				drawLineToBitmapData(bmpData, 1, 0, 63, 62, 0xFF00FFFF);
				bmpData.floodFill(62, 1, 0x80008080);
				drawTextToBitmapData(bmpData, "~" + (m_rightEdge - 1) + "," + m_topEdge , 60, 8);
				viewSaveBitmapData(m_testClampView2);
				
				// set clamp view position #2
				viewSetPosition(m_testClampView2,
								m_rightEdge - viewGetBaseWidth(m_testClampView2),
								m_topEdge);
				
				// make views visible
				viewSetVisible(m_testClampView1, true);
				viewSetVisible(m_testClampView2, true);
			}
			else
			{
				// make views invisible
				viewSetVisible(m_testClampView1, false);
				viewSetVisible(m_testClampView2, false);
			}
			
			// save & quit
			//textureSaveAsPng(m_testMainTex, "C:\\Users\\Randall Hedglin\\Desktop\\launch.png", m_extWidth, m_extHeight); System.exit(0);
			
			// update current touch positions
			for(c = 0; c < m_maxTouches; c++)
			{
				// check active flag
				if(m_touchActive[c])
				{
					// location string & size
					var str1  :String = new String(m_touchX[c] + "," + m_touchY[c]);
					var size1 :int    = (str1.length * 6) + 1;
					
					// touch id string & size
					var str2  :String = new String("(" + m_rawTouchAppId[c] + ")");
					var size2 :int    = (str2.length * 6) + 1;
					
					// source positions
					var srcX1 :int;
					var srcY1 :int;
					var srcX2 :int;
					var srcY2 :int;
					
					// set target color mask
					var mask :uint = m_touching[c] ? 0xFFFFFFFF : 0xFF3F3F3F;  
					
					// update texture
					bmpData = viewGetBitmapData(m_testTouchView[c]);
					drawRectToBitmapData(bmpData, 0, 0, 128, 128, 0x00000000);
					drawCircleToBitmapData(bmpData, 64, 64, 40, 0xFFFFFFFF & mask);
					bmpData.floodFill(64, 64, 0x40000000);
					drawLineToBitmapData(bmpData, 20, 20, 108, 108, 0xFFFFFFFF & mask);
					drawLineToBitmapData(bmpData, 21, 20, 108, 107, 0x80FFFFFF & mask);
					drawLineToBitmapData(bmpData, 20, 21, 107, 108, 0x80FFFFFF & mask);
					drawLineToBitmapData(bmpData, 20, 108, 108, 20, 0xFFFFFFFF & mask);
					drawLineToBitmapData(bmpData, 21, 108, 108, 21, 0x80FFFFFF & mask);
					drawLineToBitmapData(bmpData, 20, 107, 107, 20, 0x80FFFFFF & mask);
					drawLineToBitmapData(bmpData, 64, 0, 64, 127, 0xFFFFFFFF & mask);
					drawLineToBitmapData(bmpData, 0, 64, 127, 64, 0xFFFFFFFF & mask);
					if(m_touchX[c] < (m_baseWidth / 2))
						if(m_touchY[c] < (m_baseHeight / 2)) srcX1 = 65, srcY1 = 121, srcX2 = 65, srcY2 = 114; else srcX1 = 65, srcY1 = 0, srcX2 = 65, srcY2 = 7;
					else
						if(m_touchY[c] < (m_baseHeight / 2)) srcX1 = 64 - size1, srcY1 = 121, srcX2 = 64 - size2, srcY2 = 114; else srcX1 = 64 - size1, srcY1 = 0, srcX2 = 64 - size2, srcY2 = 7;
					drawRectToBitmapData(bmpData, srcX1, srcY1, size1, 7, 0x80000000);
					drawTextToBitmapData(bmpData, str1, srcX1 + 1, srcY1 + 1);
					drawRectToBitmapData(bmpData, srcX2, srcY2, size2, 7, 0x80000000);
					drawTextToBitmapData(bmpData, str2, srcX2 + 1, srcY2 + 1);
					viewSaveBitmapData(m_testTouchView[c]);
					
					// set new position
					viewSetPosition(m_testTouchView[c], m_touchX[c] - 64, m_touchY[c] - 64);
					
					// make visible
					viewSetVisible(m_testTouchView[c], true);
				}
				else
				{
					// make invisible
					viewSetVisible(m_testTouchView[c], false);
				}
			}
		}
	}
}
