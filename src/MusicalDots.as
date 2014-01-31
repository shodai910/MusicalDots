/**
 * Copyright royi ( http://wonderfl.net/user/royi )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * From http://wonderfl.net/c/v2jB
 */
package {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.media.SoundMixer;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.flash_proxy;
	import flash.utils.getTimer;
	
	[SWF(BackgroundColor=0x000000, width=465, height=465, frameRATE=60 )]
	public class MusicalDots extends Sprite{
		
		private var pos:int = 0;
		private var sw:int, sh:int;
		private var playSound:Boolean = true;
		private var vol:Number = .5;
		private var note:Number = 400;
		
		
		private var particles:Array = [];
		private var numParticles:uint = 10;
		private var particleGfx:Graphics;
		private var waveGfx:Graphics;
		private var bmpData:BitmapData;
		private var particleSprite:Sprite = new Sprite();
		private var waveSprite:Sprite = new Sprite();
		private var blur:BlurFilter;
		private var notes:Array;
		private var notesCp:Array;
		private var playing:Boolean = false;
		
		// 音階:Scale
		private var sc:Object;
		
		public function MusicalDots() {
			sc = new Object();
			sc = {C:523, D:583, E:659, F:698, G:783, A:880,B:988}
			
			// 画面の幅、高さを取得
			sw = stage.stageWidth, sh = stage.stageHeight;
			//　きらきら星のメロディ
			notes = [sc.C,sc.C,sc.G,sc.G,sc.A,sc.A,sc.G,
				sc.F,sc.F,sc.E,sc.E,sc.D,sc.D,sc.C,
				sc.G,sc.G,sc.F,sc.F,sc.E,sc.E,sc.D,
				sc.G,sc.G,sc.F,sc.F,sc.E,sc.E,sc.D,
				sc.C,sc.C,sc.G,sc.G,sc.A,sc.A,sc.G,
				sc.F,sc.F,sc.E,sc.E,sc.D,sc.D,sc.C];
			notes.reverse();
			// 連続再生用にコピー
			notesCp = notes.concat();
			
			// キャンバスの作成
			// BitmapData(幅, 高さ, 透明度, 塗りの色)
			bmpData = new BitmapData(sw, sh, false, 0x000000);  
			// Bitmap(BitmapDataインスタンス, ピクセル吸着, スムージング)
			var bmp:Bitmap = new Bitmap(bmpData, "never", true); 
			addChild(bmp);
			
			// 画面に波形とパーティクルの設置
			waveGfx     = waveSprite.graphics;
			particleGfx = particleSprite.graphics;
			addChild(waveSprite);
			addChild(particleSprite);
			
			// ぼかしの設定
			// BlurFilter(水平方向ぼかし量, 垂直方向ぼかし量, 品質)
			blur = new BlurFilter(12, 12, 1);
			
			
			
			// 画面内パーティクルの位置、移動距離を設定
			for(var i:int = 0; i < numParticles; i++) {
				particles[i] = {
					x:Math.random() * sw,
						y:Math.random() * sh,
						vx:Math.random() * 2 - 1,
						vy:Math.random() * 2 - 1
				};
			}
			
			// 音関係
			var sound:Sound = new Sound();
			sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			sound.play();
			
			// 画面クリック
			stage.addEventListener(MouseEvent.CLICK, onClick);
			
			// 毎フレーム
			addEventListener(Event.ENTER_FRAME, loop);
		}
		
		// パーティクルの描画
		private function loop(evt:Event):void {
			particleGfx.clear();
			for(var i:int = 0; i < numParticles; i++) {
				for( var j:int = i+1; j < numParticles; j++) {
					// パーティクル間に線を描画
					react(particles[i], particles[j]);
				}
				// パーティクルが移動距離が増え過ぎないようにする
				if(particles[i].vx > 1) particles.vx *= .99;
				if(particles[i].vy > 1) particles.vy *= .99;
				
				// パーティクルの移動
				particles[i].x +=  particles[i].vx;
				particles[i].y += particles[i].vy;
				
				// パーティクルが画面外に出た場合、位置を初期化
				if(particles[i].x > sw) particles[i].x = 0;
				if(particles[i].x < 0)  particles[i].x = sw;
				if(particles[i].y > sh) particles[i].y = 0;
				if(particles[i].y < 0)  particles[i].y = sh;
				
				// パーティクルの色と形指定
				// Graphics.begenFill(塗りの色)
				particleGfx.beginFill(0x00ffff);
				// Graphics.drawCircle(中心のx座標, 中心のy座標, 半径)
				particleGfx.drawCircle(particles[i].x, particles[i].y, 2); 
				particleGfx.endFill();
			}
			// パーティクルの描画
			bmpData.draw(particleSprite);
			// 波形の描画
			bmpData.draw(waveSprite);
			// ぼかし用フィルタの設定
			// BitmapData.applyFilter(ソースイメージ, 適用範囲, 適用位置, フィルタ効果)
			bmpData.applyFilter(bmpData, bmpData.rect, new Point(), blur);
			var time:int = getTimer();
			// 画面を円状に回転
			bmpData.scroll(Math.cos(time * .001) * 2.9, Math.sin(time * .001) * 2.9);
		}
		
		// パーティクル間に線を描画
		private function react(p1:Object, p2:Object):void {
			// 斜めの距離(三平方の定理)
			var dx:Number = p2.x - p1.x;
			var dy:Number = p2.y - p1.y;
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			// 距離150pxを基準として線を描画する
			var distance:int = 150;
			if(dist < distance) {
				var vx:Number = dx * .0005;
				var vy:Number = dy * .0005;
				p1.vx += vx;
				p1.vy += vy;
				p2.vx -= vx;
				p2.vy -= vy;
				
				// 線の設定
				// Graphics.lineStayle(太さ, 色, 透明度)
				particleGfx.lineStyle(1, 0xfffffff , 1 - (dist / distance));
				// 始点の設定 Graphics.moveTo(始点のx座標, 始点のy座標)
				particleGfx.moveTo(p1.x, p1.y);
				// 終点まで線を描画 Graphics.LineTo(終点の)
				particleGfx.lineTo(p2.x, p2.y);
				
				// 距離が30未満のとき音を鳴らす
				if(!playing && dist < 30) {
					playing = true;
					
					// 連続出力用にメロディのコピーを作成
					if(notesCp.length == 0) {
						notesCp = notes.concat();
					}
					note = notesCp.pop();
					pos = 0;
					vol = .5;
					
					// 音がなった箇所の線を赤に
					particleGfx.lineStyle(7, 0xff0000, 1- (dist / distance));
					particleGfx.moveTo(p1.x, p1.y);
					particleGfx.lineTo(p2.x, p2.y);
				}
			}
		}
		
		// 音関連の設定
		private function onSampleData(evt:SampleDataEvent):void {
			const RATE:int = 44100;
			const BUFFER:int = 2048;
			
			// 垂直線の描画
			waveGfx.clear();
			waveGfx.lineStyle(0, Math.random() * 0xffffff);
			waveGfx.moveTo(0, sh * .5);
			
			for(var i:int = 0; i < BUFFER; i++) {
				// 正弦波の出力
				var phase:Number = (pos / RATE) * (Math.PI * 2);
				pos++;
				var sample:Number = Math.sin(phase * note) * vol;
				vol *= .9997;
				
				// 音声出力
				evt.data.writeFloat(sample); // left
				evt.data.writeFloat(sample); // right
				
				// 波形の描画
				waveGfx.lineTo((i / BUFFER) * sw, (sh * .5) - (sample * sh));
			}
			
			// 音が小さくなったら音声出力終了
			if(vol < .0001) {
				playing = false;
			}
		}
		
		// クリック時、パーティクルを増やす
		private function onClick(evt:MouseEvent):void {
			particles.push(particles.length);
			particles[particles.length - 1] = {
				x:Math.random() * sw,
					y:Math.random() * sh,
					vx:Math.random() * 2 - 1,
					vy:Math.random() * 2 - 1
			};
			
			numParticles++;
		}
	}
}