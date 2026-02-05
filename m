<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>IRON CLASH – FINAL LOCKED</title>
<style>
html,body{margin:0;padding:0;background:#000;color:#fff;font-family:Impact,Arial;overflow:hidden}
canvas{display:block;margin:0 auto;background:linear-gradient(#050505,#111)}
#ui{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;
background:radial-gradient(circle at center,#900 0%,#300 45%,#000 80%)}
h1{font-size:92px;letter-spacing:6px;text-shadow:0 0 45px red}
h2{font-size:42px}
button{width:360px;padding:16px;margin:10px;font-size:22px;border:none;border-radius:10px;
background:linear-gradient(#c00,#600);color:#fff;cursor:pointer;box-shadow:0 0 25px #900}
button:hover{transform:scale(1.06);background:linear-gradient(#f00,#800)}
.grid{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
.card{padding:12px;border:2px solid #700;cursor:pointer;text-align:center}
.card:hover{background:#300}
.hud{position:absolute;top:20px;left:20px;font-size:16px}
#fade{position:absolute;inset:0;background:#000;opacity:0;pointer-events:none}
textarea{width:420px;height:110px;background:#111;color:#0f0;border:1px solid #700}
</style>
</head>

<body>
<div id="ui"></div>
<div id="fade"></div>
<div class="hud" id="net"></div>
<canvas id="game" width="1280" height="720"></canvas>

<script>
/* ================= CORE ================= */
const canvas=document.getElementById("game"),ctx=canvas.getContext("2d");
const ui=document.getElementById("ui"),fade=document.getElementById("fade"),net=document.getElementById("net");

let game=false,superMeter=0,win=false,winText="";
let p1,p2,selected=null,input=[];

/* ================= AUDIO ================= */
const ac=new (window.AudioContext||window.webkitAudioContext)();
function snd(f,d=0.12){
 let o=ac.createOscillator(),g=ac.createGain();
 o.type="square";o.frequency.value=f;g.gain.value=.25;
 o.connect(g);g.connect(ac.destination);
 o.start();o.stop(ac.currentTime+d);
}

/* ================= FIGHTERS ================= */
const fighters=[
"RAZOR","ONYX","VEX","KANE","NOX","BLITZ","REAPER","TALON","EMBER",
"FANG","NOVA","SHADE","RIFT","AXEL","ZION","CRUSH","PHANTOM","WARLORD"
].map((n,i)=>({name:n,color:`hsl(${i*20},85%,45%)`}));

class Fighter{
 constructor(f,x){
  this.n=f.name;this.c=f.color;
  this.x=x;this.y=430;this.w=90;this.h=180;
  this.hp=100;this.max=100;this.state="idle";this.f=0;
 }
 draw(){
  ctx.save();
  if(this.state==="attack")ctx.translate(Math.sin(this.f)*6,0);
  if(this.state==="super"){ctx.shadowColor="red";ctx.shadowBlur=35}
  ctx.fillStyle=this.c;ctx.fillRect(this.x,this.y,this.w,this.h);
  ctx.restore();
  ctx.fillStyle="#fff";ctx.fillText(this.n,this.x,this.y-10);
 }
 hit(d){this.hp=Math.max(0,this.hp-d)}
 update(){this.f++;if(this.f>10)this.state="idle"}
}

/* ================= MENUS ================= */
function mainMenu(){
 ui.innerHTML=`
 <h1>IRON CLASH</h1>
 <button onclick="story()">STORY MODE</button>
 <button onclick="select()">LOCAL VS</button>
 <button onclick="onlineMenu()">ONLINE PvP</button>`;
}

function select(){
 ui.innerHTML="<h2>SELECT FIGHTER</h2><div class='grid'></div>";
 const g=document.querySelector(".grid");
 fighters.forEach(f=>{
  let c=document.createElement("div");
  c.className="card";c.innerText=f.name;
  c.onclick=()=>{selected=f;startLocal()};
  g.appendChild(c);
 });
}

function story(){
 ui.innerHTML="<h2>THE WAR BEGINS…</h2>";
 setTimeout(select,1200);
}

/* ================= START GAME ================= */
function startLocal(){
 ui.innerHTML="";game=true;win=false;superMeter=0;
 p1=new Fighter(selected||fighters[0],260);
 p2=new Fighter(fighters[Math.floor(Math.random()*fighters.length)],900);
}

/* ================= INPUT ================= */
document.addEventListener("keydown",e=>{
 if(!game)return;
 if(e.key==="a"){p2.hit(5);p1.state="attack";snd(140);superMeter+=5;input.push("a")}
 if(e.key==="s"){p2.hit(10);p1.state="attack";snd(90);superMeter+=10;input.push("s")}
 if(e.key==="d"&&superMeter>=100){p2.hit(45);p1.state="super";snd(40);superMeter=0}
 if(input.join("").includes("aas")){p2.hit(25);snd(60);input=[]}
 if(input.length>3)input.shift();
});

/* ================= ONLINE PvP ================= */
let pc,dc,isHost=false;
function onlineMenu(){
 ui.innerHTML=`<h2>ONLINE PvP</h2>
 <button onclick="host()">HOST</button>
 <button onclick="join()">JOIN</button>`;
}
function host(){
 isHost=true;setup();
 ui.innerHTML=`<p>Send OFFER</p><textarea id="o"></textarea>
 <p>Paste ANSWER</p><textarea id="a"></textarea>
 <button onclick="connect()">CONNECT</button>`;
}
function join(){
 isHost=false;setup();
 ui.innerHTML=`<p>Paste OFFER</p><textarea id="o"></textarea>
 <button onclick="answer()">CREATE ANSWER</button>
 <textarea id="a"></textarea>`;
}
function setup(){
 pc=new RTCPeerConnection();
 pc.onicecandidate=e=>e.candidate&&updateSDP();
 pc.ondatachannel=e=>{dc=e.channel;wire()};
 if(isHost){dc=pc.createDataChannel("ic");wire();pc.createOffer().then(o=>pc.setLocalDescription(o))}
}
function wire(){dc.onopen=()=>net.innerText="ONLINE CONNECTED";dc.onmessage=e=>p1.hit(JSON.parse(e.data))}
function updateSDP(){document.getElementById(isHost?"o":"a").value=JSON.stringify(pc.localDescription)}
async function connect(){await pc.setRemoteDescription(JSON.parse(a.value));startOnline()}
async function answer(){await pc.setRemoteDescription(JSON.parse(o.value));
 let an=await pc.createAnswer();await pc.setLocalDescription(an);
 a.value=JSON.stringify(an)}
function send(v){dc&&dc.readyState==="open"&&dc.send(JSON.stringify(v))}
function startOnline(){
 ui.innerHTML="";game=true;superMeter=0;
 p1=new Fighter(fighters[0],260);
 p2=new Fighter(fighters[1],900);
}

/* ================= LOOP ================= */
function loop(){
 ctx.clearRect(0,0,1280,720);
 if(game){
  p1.update();p2.update();p1.draw();p2.draw();
  ctx.fillStyle="red";
  ctx.fillRect(60,40,300*(p1.hp/p1.max),18);
  ctx.fillRect(920,40,300*(p2.hp/p2.max),18);
  ctx.fillStyle="yellow";
  ctx.fillRect(60,66,300*(superMeter/100),8);
  if(p1.hp<=0||p2.hp<=0){
   win=true;winText=p1.hp>0?"FINISH HIM":"DEFEAT";
   setTimeout(mainMenu,2600);game=false;
  }
 }
 if(win){
  ctx.fillStyle="rgba(0,0,0,.85)";
  ctx.fillRect(0,0,1280,720);
  ctx.fillStyle="#f00";ctx.font="64px Impact";
  ctx.fillText(winText,460,360);
 }
 requestAnimationFrame(loop);
}

mainMenu();loop();
</script>
</body>
</html>
