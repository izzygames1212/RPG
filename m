 <!DOCTYPE html>

<html lang="en">
<head>
<meta charset="UTF-8">
<title>IRON CLASH — Ultimate Build</title>
<style>
html,body{margin:0;padding:0;background:#000;color:#fff;font-family:Impact,Arial;overflow:hidden}
canvas{display:block;margin:0 auto;background:linear-gradient(#050505,#111)}
#ui{position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;flex-direction:column;background:radial-gradient(circle at center,#200,#000)}
button{font-size:22px;padding:12px 30px;margin:8px;border:none;border-radius:6px;background:#900;color:#fff;cursor:pointer}
button:hover{background:#c00}
.fade{animation:fade 1s ease}
@keyframes fade{from{opacity:0}to{opacity:1}}
</style>
</head>
<body>
<div id="ui" class="fade"></div>
<canvas id="game" width="1280" height="720"></canvas>
<script>
const canvas=document.getElementById('game'),ctx=canvas.getContext('2d');
const ui=document.getElementById('ui');
let mode=null,difficulty='NORMAL';
let p1,p2,gameActive=false,showWin=false,winText='';

const fighters=[
'RAZOR','ONYX','VEX','KANE','NOX','BLITZ','REAPER','TALON','EMBER','FANG','NOVA','SHADE','RIFT','AXEL','ZION','CRUSH','PHANTOM','WARLORD'
];

function showMenu(){ui.innerHTML=`<h1>IRON CLASH</h1> <button onclick="startStory()">STORY MODE</button> <button onclick="startArcade()">ARCADE</button> <button onclick="startSurvival()">SURVIVAL</button> <button onclick="startTraining()">TRAINING</button> <button onclick="startVersus()">VERSUS</button>`;ui.style.display='flex'}

function showScreen(html){ui.innerHTML=html;ui.style.display=html? 'flex':'none'}

class Fighter{
constructor(name,x,color,isAI=false){
this.name=name;this.x=x;this.y=430;this.w=70;this.h=150;
this.hp=100;this.max=100;this.color=color;this.isAI=isAI;this.cool=0;
}
draw(){ctx.fillStyle=this.color;ctx.fillRect(this.x,this.y,this.w,this.h);
ctx.fillStyle='#fff';ctx.font='16px Impact';ctx.fillText(this.name,this.x,this.y-10)}
attack(target){if(this.cool<=0){target.hp-=5;this.cool=25;}}
update(target){if(this.cool>0)this.cool--;if(this.isAI)aiControl(this,target)}
}

function aiControl(ai,player){
let r=Math.random();
if(difficulty==='EASY' && r<0.02)ai.attack(player);
if(difficulty==='NORMAL' && r<0.05)ai.attack(player);
if(difficulty==='HARD' && r<0.1)ai.attack(player);
}

function startFight(a,b){showScreen(null);gameActive=true;showWin=false;
p1=new Fighter(a,250,'#c00',false);
p2=new Fighter(b,900,'#444',true);
}

function endFight(text){gameActive=false;showWin=true;winText=text;
setTimeout(showMenu,2000)}

function loop(){ctx.clearRect(0,0,canvas.width,canvas.height);
if(gameActive){
p1.update(p2);p2.update(p1);
p1.draw();p2.draw();
ctx.fillStyle='red';ctx.fillRect(50,40,300*(p1.hp/p1.max),20);
ctx.fillStyle='red';ctx.fillRect(930,40,300*(p2.hp/p2.max),20);
if(p1.hp<=0)endFight(p2.name+' WINS');
if(p2.hp<=0)endFight(p1.name+' WINS');
}
if(showWin){ctx.fillStyle='rgba(0,0,0,0.7)';ctx.fillRect(0,0,1280,720);
ctx.fillStyle='#f00';ctx.font='56px Impact';ctx.fillText(winText,500,360)}
requestAnimationFrame(loop)}

function startArcade(){mode='ARCADE';difficulty='NORMAL';startFight(fighters[0],fighters[Math.floor(Math.random()*fighters.length)])}
function startStory(){mode='STORY';difficulty='NORMAL';showScreen('<h2>STORY MODE</h2><p>The underground tournament decides the fate of the world.</p><button onclick="startFight(\'RAZOR\',\'WARLORD\')">BEGIN</button>')}
function startSurvival(){mode='SURVIVAL';difficulty='HARD';startFight(fighters[0],fighters[Math.floor(Math.random()*fighters.length)])}
function startTraining(){mode='TRAINING';difficulty='EASY';startFight(fighters[0],fighters[1])}
function startVersus(){mode='VERSUS';difficulty='NORMAL';startFight(fighters[0],fighters[2])}

showMenu();
loop(); </script>

</body>
</html>

     
