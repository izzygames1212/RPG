 import pygame, random, json, os, time, sys
pygame.init()
pygame.mixer.init()

# Screen
WIDTH, HEIGHT = 640,480
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Anime Retro RPG NES")
clock = pygame.time.Clock()

# Load assets (replace URLs with local files if needed)
def load_image(name):
    try: return pygame.image.load(name).convert_alpha()
    except: return pygame.Surface((32,32))  # placeholder

player_male = load_image("player_male.png")
player_female = load_image("player_female.png")
enemy_img = load_image("enemy.png")
boss_img = load_image("boss.png")
npc_img = load_image("npc.png")

# Sounds
try: pygame.mixer.music.load("chiptune.mp3"); pygame.mixer.music.play(-1)
except: pass
try: attack_sound = pygame.mixer.Sound("attack.wav")
except: attack_sound = None

# Colors
WHITE=(255,255,255); BLACK=(0,0,0); RED=(200,0,0)
GREEN=(0,200,0); BLUE=(0,120,255); YELLOW=(255,255,0)
PURPLE=(160,0,160); ORANGE=(255,165,0)

font = pygame.font.SysFont("courier",16)
big = pygame.font.SysFont("courier",32)

# ---------- LOADING SCREEN ----------
loading_time = 4
start_time = time.time()
while time.time()-start_time < loading_time:
    screen.fill(BLACK)
    screen.blit(big.render("ANIME FIGHT LOADING...",True,YELLOW),(100,30))
    # fighters
    pygame.draw.rect(screen, RED,(150,200,60,120))
    pygame.draw.rect(screen, BLUE,(430,200,60,120))
    # effect
    if int(time.time()*5)%2==0: pygame.draw.line(screen,YELLOW,(210,260),(430,260),4)
    # progress bar
    progress = min(1,(time.time()-start_time)/loading_time)
    pygame.draw.rect(screen,WHITE,(120,450,400,20),2)
    pygame.draw.rect(screen,GREEN,(122,452,int(396*progress),16))
    pygame.display.flip()

# ---------- CHARACTER SELECT ----------
player_color_img = player_male
selecting=True
while selecting:
    screen.fill(BLACK)
    screen.blit(big.render("SELECT CHARACTER", True, YELLOW), (120, 150))
    screen.blit(player_male,(180,250))
    screen.blit(player_female,(360,250))
    screen.blit(font.render("1. Male",True,WHITE),(190,320))
    screen.blit(font.render("2. Female",True,WHITE),(370,320))
    pygame.display.flip()
    for e in pygame.event.get():
        if e.type==pygame.QUIT: pygame.quit(); sys.exit()
        if e.type==pygame.KEYDOWN:
            if e.key==pygame.K_1: player_color_img=player_male; selecting=False
            if e.key==pygame.K_2: player_color_img=player_female; selecting=False

# ---------- PLAYER ----------
player = pygame.Rect(300,220,32,32)
hp,max_hp=100,100
mp,max_mp=30,30
atk=5
gold=0
speed=4
weapon="Sword"

# ---------- WORLD ----------
ox,oy=0,0
town=pygame.Rect(250,250,120,120)
npc1=pygame.Rect(280,220,24,24)
npc2=pygame.Rect(500,400,24,24)
dungeon_rooms=[pygame.Rect(800,200,40,40),pygame.Rect(900,500,40,40)]

# ---------- ENEMY / BOSS ----------
enemy=pygame.Rect(120,120,32,32)
enemy_hp=40
boss=pygame.Rect(900,600,64,64)
boss_hp=300

quests={"talked_to_npc":False,"defeat_boss":False,"collect_gold":0}
current_dialog=""
show_dialog=False

# ---------- SAVE/LOAD ----------
SAVE="retro_anime_save.json"
def save_game():
    data={"hp":hp,"mp":mp,"atk":atk,"gold":gold,"weapon":weapon,
          "px":player.x,"py":player.y,"ox":ox,"oy":oy,
          "boss":boss_hp,"quests":quests}
    with open(SAVE,"w") as f: json.dump(data,f)
def load_game():
    global hp,mp,atk,gold,weapon,ox,oy,boss_hp,quests
    if os.path.exists(SAVE):
        with open(SAVE) as f:
            d=json.load(f)
            hp,mp,atk,gold,weapon=d["hp"],d["mp"],d["atk"],d["gold"],d["weapon"]
            player.x,player.y=d["px"],d["py"]
            ox,oy=d["ox"],d["oy"]
            boss_hp=d["boss"]
            quests=d["quests"]

# ---------- UI BAR ----------
def bar(x,y,v,m,c):
    pygame.draw.rect(screen,RED,(x,y,40,6))
    pygame.draw.rect(screen,c,(x,y,40*(v/m),6))

# ---------- MENU ----------
def menu():
    while True:
        screen.fill(BLACK)
        screen.blit(big.render("RETRO RPG ANIME NES",True,YELLOW),(50,120))
        screen.blit(font.render("1. PLAY",True,WHITE),(280,200))
        screen.blit(font.render("2. LOAD",True,WHITE),(280,230))
        screen.blit(font.render("3. QUIT",True,WHITE),(280,260))
        pygame.display.flip()
        for e in pygame.event.get():
            if e.type==pygame.QUIT: pygame.quit(); sys.exit()
            if e.type==pygame.KEYDOWN:
                if e.key==pygame.K_1: return
                if e.key==pygame.K_2: load_game(); return
                if e.key==pygame.K_3: pygame.quit(); sys.exit()
menu()
load_game()

# ---------- GAME LOOP ----------
running=True
while running:
    clock.tick(60)
    screen.fill(BLACK)
    keys=pygame.key.get_pressed()

    # Movement
    dx=(keys[pygame.K_RIGHT]-keys[pygame.K_LEFT])*speed
    dy=(keys[pygame.K_DOWN]-keys[pygame.K_UP])*speed
    player.x+=dx; player.y+=dy

    # World scroll
    if player.x<200: ox+=speed; player.x=200
    if player.x>440: ox-=speed; player.x=440
    if player.y<150: oy+=speed; player.y=150
    if player.y>330: oy-=speed; player.y=330

    # Enemy collision
    enemy_draw=enemy.move(ox,oy)
    if player.colliderect(enemy_draw):
        enemy_hp-=random.randint(atk,atk+3)
        hp-=random.randint(1,3)
        if attack_sound: attack_sound.play()
        if enemy_hp<=0:
            enemy_hp=40
            enemy.x=random.randint(50,600)
            enemy.y=random.randint(50,430)
            atk+=1; gold+=5; quests["collect_gold"]+=5

    # NPC
    if keys[pygame.K_e]:
        if player.colliderect(npc1.move(ox,oy)):
            quests["talked_to_npc"]=True
            current_dialog="NPC1: Brave hero! Defeat the dragon!"
            show_dialog=True
        elif player.colliderect(npc2.move(ox,oy)):
            current_dialog="NPC2: Collect gold to upgrade your sword!"
            show_dialog=True

    # Town healing
    if player.colliderect(town.move(ox,oy)):
        hp=max_hp; mp=max_mp
        if gold>=10: gold-=10; atk+=1

    # Dungeon rooms
    for door in dungeon_rooms:
        if player.colliderect(door.move(ox,oy)):
            current_dialog="You enter a dungeon room!"
            show_dialog=True
            player.x=100; player.y=100; ox=0; oy=0

    # Boss
    boss_draw=boss.move(ox,oy)
    if quests["talked_to_npc"] and player.colliderect(boss_draw):
        boss_hp-=random.randint(atk+5,atk+8)
        hp-=random.randint(3,6)
        if attack_sound: attack_sound.play()
        if boss_hp<=0: quests["defeat_boss"]=True

    # Draw
    screen.blit(player_color_img,player)
    screen.blit(enemy_img,enemy_draw)
    if quests["talked_to_npc"]: screen.blit(boss_img,boss_draw)
    screen.blit(npc_img,npc1.move(ox,oy))
    screen.blit(npc_img,npc2.move(ox,oy))
    pygame.draw.rect(screen, GREEN, town.move(ox,oy))
    for door in dungeon_rooms: pygame.draw.rect(screen, ORANGE, door.move(ox,oy))
    bar(player.x,player.y-8,hp,max_hp,GREEN)
    bar(player.x,player.y-16,mp,max_mp,BLUE)
    ui=font.render(f"ATK:{atk} GOLD:{gold} QUESTS:{'Boss' if quests['defeat_boss'] else 'Pending'}",True,WHITE)
    screen.blit(ui,(10,10))

    # Dialog
    if show_dialog:
        pygame.draw.rect(screen,BLACK,(80,350,480,100))
        pygame.draw.rect(screen,WHITE,(80,350,480,100),2)
        screen.blit(font.render(current_dialog,True,WHITE),(100,370))
        screen.blit(font.render("Press E to close.",True,WHITE),(100,395))
        if not keys[pygame.K_e]: show_dialog=False

    # End game
    if quests["defeat_boss"]:
        screen.blit(big.render("YOU SAVED THE LAND!",True,YELLOW),(120,220))
        pygame.display.flip(); pygame.time.delay(3000)
        break
    if hp<=0:
        screen.blit(big.render("GAME OVER",True,RED),(230,220))
        pygame.display.flip(); pygame.time.delay(3000)
        break

    pygame.display.flip()

pygame.quit()



