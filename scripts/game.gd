extends Node2D
## STARFALL: Expedition Zero — procedural landscape-first survival RPG.
## The game is intentionally asset-free so it imports on mobile without huge downloads.

const WORLD_SIZE: Vector2 = Vector2(3600.0, 2600.0)
const SAVE_PATH: String = "user://starfall_save.json"
const PLAYER_RADIUS: float = 16.0
const RESOURCE_KINDS: Array[String] = ["scrap", "crystal", "fiber", "gas", "alloy", "bio"]
const RESOURCE_NAMES: Dictionary = {
    "scrap": "خردة", "crystal": "بلورات", "fiber": "ألياف", "gas": "غاز",
    "alloy": "سبيكة", "bio": "كتلة حيوية"
}
const SKILLS: Array[Dictionary] = [
    {"id":"vitality", "name":"قلب فولاذي", "desc":"+25 صحة لكل رتبة", "cost":1, "max":5, "requires":[]},
    {"id":"runner", "name":"عدّاء النجوم", "desc":"+8% سرعة حركة", "cost":1, "max":5, "requires":[]},
    {"id":"scavenger", "name":"عين المنقّب", "desc":"+15% موارد من العقد", "cost":1, "max":4, "requires":[]},
    {"id":"gunner", "name":"رامي محترف", "desc":"+20% ضرر السلاح", "cost":2, "max":5, "requires":["vitality"]},
    {"id":"medic", "name":"ترميم حيوي", "desc":"استعادة صحة كل موجة", "cost":2, "max":3, "requires":["vitality"]},
    {"id":"engineer", "name":"مهندس ميداني", "desc":"الأبراج أرخص وأقوى", "cost":2, "max":4, "requires":["scavenger"]},
    {"id":"overclock", "name":"تجاوز الحدود", "desc":"+25% سرعة إطلاق", "cost":3, "max":3, "requires":["gunner"]},
    {"id":"drone", "name":"رفيق آلي", "desc":"درون يطلق على أقرب عدو", "cost":4, "max":1, "requires":["engineer","gunner"]},
    {"id":"phoenix", "name":"بروتوكول العنقاء", "desc":"إنقاذ مرة واحدة عند الموت", "cost":5, "max":1, "requires":["medic","overclock"]}
]
const RECIPES: Array[Dictionary] = [
    {"id":"medkit","name":"حزمة إسعاف","desc":"استعادة 55 صحة","cost":{"bio":2,"fiber":2},"kind":"consumable"},
    {"id":"ammo","name":"ذخيرة مشحونة","desc":"تعزيز ضرر 30 ثانية","cost":{"scrap":8,"crystal":2},"kind":"consumable"},
    {"id":"turret","name":"برج دفاع آلي","desc":"يطلق تلقائياً على الأعداء","cost":{"scrap":18,"alloy":3,"crystal":2},"kind":"building"},
    {"id":"wall","name":"حاجز طاقة","desc":"يعرقل الأعداء","cost":{"scrap":10,"alloy":2},"kind":"building"},
    {"id":"refinery","name":"مصفاة موارد","desc":"تولد خردة بمرور الوقت","cost":{"scrap":20,"gas":3},"kind":"building"},
    {"id":"grenade","name":"قنبلة نجمية","desc":"ضرر انفجاري حول اللاعب","cost":{"gas":2,"crystal":3,"scrap":5},"kind":"consumable"},
    {"id":"upgrade_weapon","name":"ترقية السلاح","desc":"+7 ضرر دائم","cost":{"scrap":25,"alloy":4,"crystal":4},"kind":"upgrade"},
    {"id":"upgrade_suit","name":"تقوية البدلة","desc":"+35 صحة قصوى","cost":{"scrap":20,"bio":5,"alloy":2},"kind":"upgrade"}
]
const QUESTS: Array[Dictionary] = [
    {"id":"gather","name":"جامع الخردة","desc":"اجمع 30 خردة","target":30,"type":"scrap","reward":2},
    {"id":"hunt","name":"صائد الكائنات","desc":"اقضِ على 12 عدواً","target":12,"type":"kills","reward":3},
    {"id":"crystal","name":"نبض البلورات","desc":"اجمع 12 بلورة","target":12,"type":"crystal","reward":2},
    {"id":"build","name":"مهندس الميدان","desc":"ابنِ 3 منشآت","target":3,"type":"builds","reward":3},
    {"id":"boss","name":"كاسر العمالقة","desc":"اهزم زعيمًا واحدًا","target":1,"type":"bosses","reward":5}
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var player_pos: Vector2 = WORLD_SIZE * 0.5
var player_vel: Vector2 = Vector2.ZERO
var player_hp: float = 100.0
var max_hp: float = 100.0
var player_level: int = 1
var xp: int = 0
var xp_next: int = 40
var skill_points: int = 0
var skill_levels: Dictionary = {}
var resources: Dictionary = {"scrap":25,"crystal":5,"fiber":8,"gas":2,"alloy":0,"bio":3}
var inventory: Dictionary = {"medkit":1,"grenade":0,"ammo_buff":0}
var weapon_damage: float = 18.0
var fire_cooldown: float = 0.0
var buff_time: float = 0.0
var attack_cooldown: float = 0.0
var enemies: Array[Dictionary] = []
var resource_nodes: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var wave: int = 1
var wave_timer: float = 18.0
var wave_kills: int = 0
var total_kills: int = 0
var total_builds: int = 0
var total_bosses: int = 0
var credits: int = 0
var world_time: float = 0.0
var game_over: bool = false
var paused: bool = false
var show_inventory: bool = false
var show_skills: bool = false
var show_crafting: bool = false
var show_quests: bool = false
var show_map: bool = false
var toast: String = "مرحباً بك في القطاع صفر"
var toast_timer: float = 4.0
var auto_fire: bool = true
var selected_recipe: int = 0
var selected_skill: int = 0
var selected_build: String = "turret"
var touch_move: Vector2 = Vector2.ZERO
var touch_origin: Vector2 = Vector2.ZERO
var touch_id: int = -999
var fire_touch: bool = false
var mouse_aim: Vector2 = Vector2.RIGHT
var screen_size: Vector2 = Vector2(1280,720)
var camera_offset: Vector2 = Vector2.ZERO
var hud_buttons: Array[Dictionary] = []
var interact_buttons: Array[Dictionary] = []
var damage_flash: float = 0.0
var boss_spawned_this_wave: bool = false

func _ready() -> void:
    rng.randomize()
    screen_size = get_viewport_rect().size
    _init_skill_levels()
    _spawn_world()
    _spawn_wave(true)
    _load_game()
    get_viewport().size_changed.connect(_on_viewport_changed)
    _notify("اجمع الموارد، طوّر مهاراتك، واصمد أمام الموجات.")
    queue_redraw()

func _init_skill_levels() -> void:
    for skill: Dictionary in SKILLS:
        skill_levels[skill["id"]] = 0

func _on_viewport_changed() -> void:
    screen_size = get_viewport_rect().size
    queue_redraw()

func _process(delta: float) -> void:
    var dt: float = minf(delta, 0.05)
    if not paused and not game_over and not _is_overlay_open():
        _update_game(dt)
    else:
        toast_timer = maxf(0.0, toast_timer - dt)
    queue_redraw()

func _is_overlay_open() -> bool:
    return show_inventory or show_skills or show_crafting or show_quests or show_map

func _update_game(dt: float) -> void:
    world_time += dt
    fire_cooldown = maxf(0.0, fire_cooldown - dt)
    attack_cooldown = maxf(0.0, attack_cooldown - dt)
    buff_time = maxf(0.0, buff_time - dt)
    damage_flash = maxf(0.0, damage_flash - dt * 2.0)
    wave_timer -= dt
    if toast_timer > 0.0:
        toast_timer -= dt
    _update_player(dt)
    _update_enemies(dt)
    _update_bullets(dt)
    _update_buildings(dt)
    _update_particles(dt)
    _update_drops(dt)
    if wave_timer <= 0.0 and enemies.is_empty():
        wave += 1
        wave_timer = maxf(9.0, 19.0 - float(wave) * 0.35)
        boss_spawned_this_wave = false
        _spawn_wave(false)
        if int(skill_levels.get("medic",0)) > 0:
            player_hp = minf(max_hp, player_hp + 12.0 * float(skill_levels["medic"]))
        _notify("بدأت الموجة %d!" % wave)
    if int(skill_levels.get("drone",0)) > 0 and fire_cooldown <= 0.0:
        _drone_attack()
    if player_hp <= 0.0:
        if int(skill_levels.get("phoenix",0)) > 0:
            skill_levels["phoenix"] = 0
            player_hp = max_hp * 0.45
            _notify("بروتوكول العنقاء أنقذك! لن يتكرر.")
        else:
            game_over = true
            _notify("انتهت الرحلة. يمكنك إعادة المحاولة.")
    if int(resources.get("scrap",0)) >= 999999:
        resources["scrap"] = 999999

func _update_player(dt: float) -> void:
    var input_dir: Vector2 = Vector2.ZERO
    input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    if touch_move.length() > 0.1:
        input_dir = touch_move
    if input_dir.length() > 1.0:
        input_dir = input_dir.normalized()
    var speed: float = 220.0 * (1.0 + 0.08 * float(skill_levels.get("runner",0)))
    player_vel = input_dir * speed
    player_pos += player_vel * dt
    player_pos.x = clampf(player_pos.x, 35.0, WORLD_SIZE.x - 35.0)
    player_pos.y = clampf(player_pos.y, 35.0, WORLD_SIZE.y - 35.0)
    if fire_touch or Input.is_action_pressed("ui_accept") or auto_fire:
        if fire_cooldown <= 0.0 and not enemies.is_empty():
            _fire_at_nearest()
    if Input.is_action_just_pressed("ui_cancel"):
        if _is_overlay_open():
            _close_overlays()
        else:
            paused = not paused

func _spawn_world() -> void:
    resource_nodes.clear()
    buildings.clear()
    enemies.clear()
    bullets.clear()
    for i: int in range(190):
        var pos: Vector2 = _random_world_point()
        var roll: float = rng.randf()
        var kind: String = "scrap"
        if roll < 0.23:
            kind = "crystal"
        elif roll < 0.42:
            kind = "fiber"
        elif roll < 0.56:
            kind = "gas"
        elif roll < 0.68:
            kind = "bio"
        elif roll < 0.79:
            kind = "alloy"
        var amount: int = rng.randi_range(2, 7)
        resource_nodes.append({"pos":pos,"kind":kind,"amount":amount,"radius":rng.randf_range(13.0,22.0),"alive":true})
    for i: int in range(25):
        var pos: Vector2 = _random_world_point()
        buildings.append({"kind":"ruin","pos":pos,"hp":100.0,"max_hp":100.0,"cooldown":0.0,"decor":true})

func _random_world_point() -> Vector2:
    return Vector2(rng.randf_range(50.0,WORLD_SIZE.x-50.0), rng.randf_range(50.0,WORLD_SIZE.y-50.0))

func _spawn_wave(initial: bool) -> void:
    var count: int = 4 + wave * 2
    if initial:
        count = 5
    for i: int in range(count):
        _spawn_enemy(false)
    if wave >= 3 and wave % 3 == 0 and not boss_spawned_this_wave:
        _spawn_enemy(true)
        boss_spawned_this_wave = true

func _spawn_enemy(is_boss: bool) -> void:
    var pos: Vector2 = _random_world_point()
    var attempts: int = 0
    while pos.distance_to(player_pos) < 500.0 and attempts < 20:
        pos = _random_world_point()
        attempts += 1
    var kind: String = "stalker"
    if is_boss:
        kind = "titan"
    elif rng.randf() < 0.28:
        kind = "ranged"
    elif rng.randf() < 0.22:
        kind = "brute"
    var hp: float = 35.0 + float(wave) * 7.0
    var speed: float = 78.0 + minf(35.0,float(wave)*1.3)
    var radius: float = 15.0
    if kind == "ranged":
        hp *= 0.78
        speed *= 0.8
    elif kind == "brute":
        hp *= 2.2
        speed *= 0.62
        radius = 23.0
    elif kind == "titan":
        hp *= 13.0
        speed *= 0.52
        radius = 48.0
    enemies.append({"pos":pos,"hp":hp,"max_hp":hp,"speed":speed,"radius":radius,"kind":kind,"attack":rng.randf_range(0.2,1.0),"hit":0.0})

func _update_enemies(dt: float) -> void:
    for i: int in range(enemies.size()-1,-1,-1):
        var enemy: Dictionary = enemies[i]
        var pos: Vector2 = enemy["pos"]
        var to_player: Vector2 = player_pos - pos
        var distance: float = to_player.length()
        enemy["attack"] = maxf(0.0,float(enemy["attack"])-dt)
        enemy["hit"] = maxf(0.0,float(enemy["hit"])-dt)
        if str(enemy["kind"]) == "ranged" and distance < 360.0 and distance > 210.0:
            var side: Vector2 = Vector2(-to_player.y,to_player.x).normalized()
            pos += side * sin(world_time*2.0 + float(i)) * float(enemy["speed"]) * 0.35 * dt
        elif distance > float(enemy["radius"]) + PLAYER_RADIUS + 5.0:
            pos += to_player.normalized() * float(enemy["speed"]) * dt
        if distance < float(enemy["radius"]) + PLAYER_RADIUS + 5.0 and float(enemy["attack"]) <= 0.0:
            player_hp -= 8.0 + float(wave)*0.7
            damage_flash = 1.0
            enemy["attack"] = 0.85
            _burst(player_pos, Color("#ff5677"), 5)
        if str(enemy["kind"]) == "ranged" and distance < 360.0 and float(enemy["attack"]) <= 0.0:
            _enemy_shot(pos)
            enemy["attack"] = 1.7
        enemy["pos"] = pos
        enemies[i] = enemy

func _enemy_shot(from_pos: Vector2) -> void:
    var direction: Vector2 = (player_pos - from_pos).normalized()
    bullets.append({"pos":from_pos,"vel":direction*290.0,"damage":7.0+float(wave)*0.5,"friendly":false,"life":2.2,"radius":5.0})

func _update_bullets(dt: float) -> void:
    for i: int in range(bullets.size()-1,-1,-1):
        var bullet: Dictionary = bullets[i]
        bullet["pos"] = (bullet["pos"] as Vector2) + (bullet["vel"] as Vector2) * dt
        bullet["life"] = float(bullet["life"]) - dt
        var remove: bool = float(bullet["life"]) <= 0.0
        if bool(bullet["friendly"]):
            for j: int in range(enemies.size()-1,-1,-1):
                var enemy: Dictionary = enemies[j]
                if (enemy["pos"] as Vector2).distance_to(bullet["pos"]) < float(enemy["radius"]) + float(bullet["radius"]):
                    enemy["hp"] = float(enemy["hp"]) - float(bullet["damage"])
                    enemy["hit"] = 0.12
                    enemies[j] = enemy
                    _burst(bullet["pos"], Color("#5df6ff"), 3)
                    remove = true
                    if float(enemy["hp"]) <= 0.0:
                        _kill_enemy(j)
                    break
        else:
            if (bullet["pos"] as Vector2).distance_to(player_pos) < PLAYER_RADIUS + float(bullet["radius"]):
                player_hp -= float(bullet["damage"])
                damage_flash = 0.7
                remove = true
        if remove:
            bullets.remove_at(i)
        else:
            bullets[i] = bullet

func _kill_enemy(index: int) -> void:
    var enemy: Dictionary = enemies[index]
    var pos: Vector2 = enemy["pos"]
    var is_boss: bool = str(enemy["kind"]) == "titan"
    total_kills += 1
    wave_kills += 1
    xp += 18 if is_boss else 7
    credits += 30 if is_boss else 4
    drops.append({"pos":pos,"kind":"scrap","amount":rng.randi_range(2,8) if not is_boss else 35,"life":25.0})
    if rng.randf() < 0.45 or is_boss:
        drops.append({"pos":pos+Vector2(12,5),"kind":"crystal","amount":rng.randi_range(1,4) if not is_boss else 12,"life":25.0})
    if is_boss:
        total_bosses += 1
        skill_points += 2
        _notify("سقط العملاق! +2 نقطة مهارة")
        _quest_check("bosses")
    enemies.remove_at(index)
    _quest_check("kills")
    _check_level_up()

func _check_level_up() -> void:
    while xp >= xp_next:
        xp -= xp_next
        player_level += 1
        xp_next = int(float(xp_next) * 1.32) + 12
        skill_points += 1
        max_hp += 8.0
        player_hp = minf(max_hp,player_hp+30.0)
        _notify("ارتقيت إلى المستوى %d! +نقطة مهارة" % player_level)

func _fire_at_nearest() -> void:
    var nearest: Dictionary = {}
    var best: float = INF
    for enemy: Dictionary in enemies:
        var distance: float = (enemy["pos"] as Vector2).distance_to(player_pos)
        if distance < best:
            best = distance
            nearest = enemy
    if nearest.is_empty():
        return
    var direction: Vector2 = ((nearest["pos"] as Vector2)-player_pos).normalized()
    var damage: float = weapon_damage * (1.0 + 0.2*float(skill_levels.get("gunner",0)))
    if buff_time > 0.0:
        damage *= 1.65
    bullets.append({"pos":player_pos+direction*24.0,"vel":direction*600.0,"damage":damage,"friendly":true,"life":1.6,"radius":6.0})
    var rate: float = 0.42 / (1.0 + 0.25*float(skill_levels.get("overclock",0)))
    fire_cooldown = rate
    mouse_aim = direction

func _drone_attack() -> void:
    if enemies.is_empty():
        return
    var nearest: Dictionary = {}
    var best: float = INF
    for enemy: Dictionary in enemies:
        var d: float = (enemy["pos"] as Vector2).distance_to(player_pos)
        if d < best:
            best = d
            nearest = enemy
    if nearest.is_empty() or best > 500.0:
        return
    var direction: Vector2 = ((nearest["pos"] as Vector2)-player_pos).normalized()
    bullets.append({"pos":player_pos+Vector2(0,-30),"vel":direction*520.0,"damage":weapon_damage*0.42,"friendly":true,"life":1.4,"radius":4.0})
    fire_cooldown = 0.85

func _update_buildings(dt: float) -> void:
    for i: int in range(buildings.size()-1,-1,-1):
        var b: Dictionary = buildings[i]
        b["cooldown"] = maxf(0.0,float(b.get("cooldown",0.0))-dt)
        if str(b["kind"]) == "turret" and float(b["cooldown"]) <= 0.0:
            var target: Dictionary = {}
            var best: float = 360.0
            for enemy: Dictionary in enemies:
                var d: float = (enemy["pos"] as Vector2).distance_to(b["pos"])
                if d < best:
                    best = d
                    target = enemy
            if not target.is_empty():
                var direction: Vector2 = ((target["pos"] as Vector2)-(b["pos"] as Vector2)).normalized()
                bullets.append({"pos":b["pos"],"vel":direction*460.0,"damage":weapon_damage*0.65+float(skill_levels.get("engineer",0))*3.0,"friendly":true,"life":1.2,"radius":5.0})
                b["cooldown"] = 0.72
        elif str(b["kind"]) == "refinery" and float(b["cooldown"]) <= 0.0:
            resources["scrap"] = int(resources.get("scrap",0))+1
            b["cooldown"] = 5.0
        buildings[i] = b

func _update_particles(dt: float) -> void:
    for i: int in range(particles.size()-1,-1,-1):
        var p: Dictionary = particles[i]
        p["life"] = float(p["life"])-dt
        p["pos"] = (p["pos"] as Vector2)+(p["vel"] as Vector2)*dt
        p["vel"] = (p["vel"] as Vector2)*0.94
        if float(p["life"]) <= 0.0:
            particles.remove_at(i)
        else:
            particles[i] = p

func _burst(pos: Vector2, color: Color, count: int) -> void:
    for i: int in range(count):
        var angle: float = rng.randf_range(0.0,TAU)
        var speed: float = rng.randf_range(30.0,160.0)
        particles.append({"pos":pos,"vel":Vector2.RIGHT.rotated(angle)*speed,"color":color,"life":rng.randf_range(0.2,0.65)})

func _update_drops(dt: float) -> void:
    for i: int in range(drops.size()-1,-1,-1):
        var drop: Dictionary = drops[i]
        drop["life"] = float(drop["life"])-dt
        if (drop["pos"] as Vector2).distance_to(player_pos) < 50.0:
            var kind: String = str(drop["kind"])
            resources[kind] = int(resources.get(kind,0))+int(drop["amount"])
            drops.remove_at(i)
        elif float(drop["life"]) <= 0.0:
            drops.remove_at(i)
        else:
            drops[i] = drop

func _collect_nearby() -> void:
    var collected: int = 0
    for i: int in range(resource_nodes.size()-1,-1,-1):
        var node: Dictionary = resource_nodes[i]
        if bool(node["alive"]) and (node["pos"] as Vector2).distance_to(player_pos) < float(node["radius"])+65.0:
            var kind: String = str(node["kind"])
            var amount: int = int(node["amount"])
            amount = int(ceil(float(amount)*(1.0+0.15*float(skill_levels.get("scavenger",0)))))
            resources[kind] = int(resources.get(kind,0))+amount
            node["alive"] = false
            resource_nodes[i] = node
            collected += amount
            _burst(node["pos"],_resource_color(kind),8)
            _quest_check(kind)
    if collected > 0:
        _notify("جمعت %d من الموارد" % collected)
    else:
        _notify("اقترب من عقدة مورد ثم اضغط جمع")
    _check_quests()

func _place_building(kind: String) -> void:
    var cost: Dictionary = {}
    if kind == "turret":
        cost = {"scrap":18,"alloy":3,"crystal":2}
    elif kind == "wall":
        cost = {"scrap":10,"alloy":2}
    elif kind == "refinery":
        cost = {"scrap":20,"gas":3}
    var discount: float = maxf(0.45,1.0-0.08*float(skill_levels.get("engineer",0)))
    for key: String in cost:
        if int(resources.get(key,0)) < int(ceil(float(cost[key])*discount)):
            _notify("موارد غير كافية")
            return
    for key: String in cost:
        resources[key] = int(resources.get(key,0))-int(ceil(float(cost[key])*discount))
    buildings.append({"kind":kind,"pos":player_pos+Vector2(55,20).rotated(mouse_aim.angle()),"hp":120.0,"max_hp":120.0,"cooldown":0.5,"decor":false})
    total_builds += 1
    _quest_check("builds")
    _notify("تم بناء %s" % _building_name(kind))

func _craft(recipe: Dictionary) -> void:
    var cost: Dictionary = recipe["cost"]
    for key: String in cost:
        if int(resources.get(key,0)) < int(cost[key]):
            _notify("موارد غير كافية لصناعة %s" % recipe["name"])
            return
    for key: String in cost:
        resources[key] = int(resources.get(key,0))-int(cost[key])
    var id: String = str(recipe["id"])
    if id == "medkit":
        inventory["medkit"] = int(inventory.get("medkit",0))+1
    elif id == "ammo":
        buff_time = 30.0
        inventory["ammo_buff"] = int(inventory.get("ammo_buff",0))+1
    elif id == "turret" or id == "wall" or id == "refinery":
        _place_building_paid(id)
    elif id == "grenade":
        inventory["grenade"] = int(inventory.get("grenade",0))+1
    elif id == "upgrade_weapon":
        weapon_damage += 7.0
    elif id == "upgrade_suit":
        max_hp += 35.0
        player_hp = minf(max_hp,player_hp+35.0)
    _notify("تم التصنيع: %s" % recipe["name"])

func _place_building_paid(kind: String) -> void:
    buildings.append({"kind":kind,"pos":player_pos+Vector2(52,0).rotated(mouse_aim.angle()),"hp":130.0,"max_hp":130.0,"cooldown":0.4,"decor":false})
    total_builds += 1
    _quest_check("builds")

func _use_medkit() -> void:
    if int(inventory.get("medkit",0)) > 0 and player_hp < max_hp:
        inventory["medkit"] = int(inventory["medkit"])-1
        player_hp = minf(max_hp,player_hp+55.0)
        _notify("استعدت 55 صحة")
    else:
        _notify("لا توجد حزمة إسعاف أو صحتك ممتلئة")

func _use_grenade() -> void:
    if int(inventory.get("grenade",0)) <= 0:
        _notify("اصنع قنبلة نجمية أولاً")
        return
    inventory["grenade"] = int(inventory["grenade"])-1
    for i: int in range(enemies.size()-1,-1,-1):
        var enemy: Dictionary = enemies[i]
        if (enemy["pos"] as Vector2).distance_to(player_pos) < 230.0:
            enemy["hp"] = float(enemy["hp"])-110.0
            enemies[i] = enemy
            _burst(enemy["pos"],Color("#ff9e5b"),18)
            if float(enemy["hp"]) <= 0.0:
                _kill_enemy(i)
    _burst(player_pos,Color("#ff9e5b"),45)
    _notify("انفجار نجمي!")

func _buy_skill(index: int) -> void:
    if index < 0 or index >= SKILLS.size():
        return
    var skill: Dictionary = SKILLS[index]
    var id: String = str(skill["id"])
    var level: int = int(skill_levels.get(id,0))
    if level >= int(skill["max"]):
        _notify("المهارة مكتملة")
        return
    if skill_points < int(skill["cost"]):
        _notify("لا تملك نقاط مهارة كافية")
        return
    for req: String in skill["requires"]:
        if int(skill_levels.get(req,0)) <= 0:
            _notify("تحتاج فتح مهارة المتطلبات أولاً")
            return
    skill_points -= int(skill["cost"])
    skill_levels[id] = level+1
    if id == "vitality":
        max_hp += 25.0
        player_hp += 25.0
    _notify("تم تطوير: %s" % skill["name"])

func _quest_check(kind: String) -> void:
    for quest: Dictionary in QUESTS:
        var id: String = str(quest["id"])
        if str(quest["type"]) == kind and not _quest_completed(id) and _quest_progress(quest) >= int(quest["target"]):
            credits += int(quest["reward"])*10
            skill_points += int(quest["reward"])
            _set_quest_completed(id)
            _notify("مهمة مكتملة: %s | +%d نقطة مهارة" % [quest["name"],int(quest["reward"])])

func _quest_progress(quest: Dictionary) -> int:
    var kind: String = str(quest["type"])
    if kind == "kills":
        return total_kills
    if kind == "builds":
        return total_builds
    if kind == "bosses":
        return total_bosses
    return int(resources.get(kind,0))

func _quest_completed(id: String) -> bool:
    return bool(_quest_state().get(id,false))

func _set_quest_completed(id: String) -> void:
    var state: Dictionary = _quest_state()
    state[id] = true
    _write_quest_state(state)

var quest_flags: Dictionary = {}
func _quest_state() -> Dictionary:
    return quest_flags
func _write_quest_state(value: Dictionary) -> void:
    quest_flags = value

func _check_quests() -> void:
    for quest: Dictionary in QUESTS:
        _quest_check(str(quest["type"]))

func _notify(message: String) -> void:
    toast = message
    toast_timer = 2.8

func _resource_color(kind: String) -> Color:
    match kind:
        "scrap": return Color("#f0b35d")
        "crystal": return Color("#63f4ff")
        "fiber": return Color("#8be58a")
        "gas": return Color("#b48cff")
        "alloy": return Color("#c0cad8")
        "bio": return Color("#ff79b8")
        _: return Color.WHITE

func _building_name(kind: String) -> String:
    match kind:
        "turret": return "برج دفاع"
        "wall": return "حاجز طاقة"
        "refinery": return "مصفاة"
        _: return kind

func _close_overlays() -> void:
    show_inventory = false
    show_skills = false
    show_crafting = false
    show_quests = false
    show_map = false

func _save_game() -> void:
    var data: Dictionary = {
        "player_pos":[player_pos.x,player_pos.y],"player_hp":player_hp,"max_hp":max_hp,
        "player_level":player_level,"xp":xp,"xp_next":xp_next,"skill_points":skill_points,
        "skill_levels":skill_levels,"resources":resources,"inventory":inventory,
        "weapon_damage":weapon_damage,"wave":wave,"wave_timer":wave_timer,"credits":credits,
        "total_kills":total_kills,"total_builds":total_builds,"total_bosses":total_bosses,
        "quest_flags":quest_flags,"buildings":buildings
    }
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()
        _notify("تم حفظ تقدمك على الجهاز")
    else:
        _notify("تعذر حفظ اللعبة")

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not (parsed is Dictionary):
        return
    var data: Dictionary = parsed
    if data.has("player_pos"):
        var p: Array = data["player_pos"]
        player_pos = Vector2(float(p[0]),float(p[1]))
    player_hp = float(data.get("player_hp",player_hp))
    max_hp = float(data.get("max_hp",max_hp))
    player_level = int(data.get("player_level",player_level))
    xp = int(data.get("xp",xp))
    xp_next = int(data.get("xp_next",xp_next))
    skill_points = int(data.get("skill_points",skill_points))
    skill_levels = data.get("skill_levels",skill_levels)
    resources = data.get("resources",resources)
    inventory = data.get("inventory",inventory)
    weapon_damage = float(data.get("weapon_damage",weapon_damage))
    wave = int(data.get("wave",wave))
    wave_timer = float(data.get("wave_timer",wave_timer))
    credits = int(data.get("credits",credits))
    total_kills = int(data.get("total_kills",total_kills))
    total_builds = int(data.get("total_builds",total_builds))
    total_bosses = int(data.get("total_bosses",total_bosses))
    quest_flags = data.get("quest_flags",{})
    buildings = data.get("buildings",buildings)

func _draw() -> void:
    screen_size = get_viewport_rect().size
    if screen_size.x < screen_size.y:
        _draw_portrait_warning()
        return
    camera_offset = player_pos - screen_size * 0.5
    camera_offset.x = clampf(camera_offset.x,0.0,maxf(0.0,WORLD_SIZE.x-screen_size.x))
    camera_offset.y = clampf(camera_offset.y,0.0,maxf(0.0,WORLD_SIZE.y-screen_size.y))
    _draw_world()
    _draw_hud()
    if show_inventory:
        _draw_inventory()
    elif show_skills:
        _draw_skills()
    elif show_crafting:
        _draw_crafting()
    elif show_quests:
        _draw_quests()
    elif show_map:
        _draw_map()
    if paused:
        _draw_pause()
    if game_over:
        _draw_game_over()
    if damage_flash > 0.0:
        draw_rect(Rect2(Vector2.ZERO,screen_size),Color(1.0,0.05,0.2,damage_flash*0.14),true)
    if toast_timer > 0.0:
        _draw_toast()

func _draw_portrait_warning() -> void:
    draw_rect(Rect2(Vector2.ZERO,screen_size),Color("#07101f"),true)
    _center_text("STARFALL: EXPEDITION ZERO",screen_size.y*0.38,30,Color("#65f4ff"))
    _center_text("أدر الهاتف إلى الوضع الأفقي للعب",screen_size.y*0.52,24,Color.WHITE)
    _center_text("Landscape mode required",screen_size.y*0.60,16,Color("#9daac4"))

func _draw_world() -> void:
    draw_rect(Rect2(Vector2.ZERO,screen_size),Color("#0a1224"),true)
    var grid: float = 64.0
    var start_x: float = -fposmod(camera_offset.x,grid)
    var start_y: float = -fposmod(camera_offset.y,grid)
    var x: float = start_x
    while x < screen_size.x:
        draw_line(Vector2(x,0),Vector2(x,screen_size.y),Color(0.16,0.31,0.47,0.22),1.0)
        x += grid
    var y: float = start_y
    while y < screen_size.y:
        draw_line(Vector2(0,y),Vector2(screen_size.x,y),Color(0.16,0.31,0.47,0.22),1.0)
        y += grid
    for i: int in range(65):
        var sx: float = fposmod(float(i*197)+float(int(camera_offset.x*0.07)),screen_size.x)
        var sy: float = fposmod(float(i*113)+float(int(camera_offset.y*0.09)),screen_size.y)
        draw_circle(Vector2(sx,sy),1.2,Color(0.3,0.7,0.95,0.28))
    for node: Dictionary in resource_nodes:
        if not bool(node["alive"]):
            continue
        var p: Vector2 = (node["pos"] as Vector2)-camera_offset
        if _on_screen(p,45.0):
            var color: Color = _resource_color(str(node["kind"]))
            draw_circle(p,float(node["radius"])+5.0,Color(color.r,color.g,color.b,0.12))
            draw_colored_polygon(PackedVector2Array([p+Vector2(0,-float(node["radius"])),p+Vector2(float(node["radius"]),0),p+Vector2(0,float(node["radius"])),p+Vector2(-float(node["radius"]),0)]),color)
            draw_circle(p,4.0,Color("#13213a"))
    for b: Dictionary in buildings:
        var p: Vector2 = (b["pos"] as Vector2)-camera_offset
        if _on_screen(p,65.0):
            _draw_building(p,str(b["kind"]),bool(b.get("decor",false)))
    for drop: Dictionary in drops:
        var p: Vector2 = (drop["pos"] as Vector2)-camera_offset
        if _on_screen(p,25.0):
            draw_circle(p,8.0,Color("#f5d66c"))
            draw_circle(p,3.0,Color("#fff4b2"))
    for bullet: Dictionary in bullets:
        var p: Vector2 = (bullet["pos"] as Vector2)-camera_offset
        if _on_screen(p,10.0):
            var color: Color = Color("#5df6ff") if bool(bullet["friendly"]) else Color("#ff5877")
            draw_line(p-(bullet["vel"] as Vector2).normalized()*10.0,p,color,4.0)
            draw_circle(p,3.0,Color.WHITE)
    for enemy: Dictionary in enemies:
        var p: Vector2 = (enemy["pos"] as Vector2)-camera_offset
        if _on_screen(p,70.0):
            _draw_enemy(p,enemy)
    for particle: Dictionary in particles:
        var p: Vector2 = (particle["pos"] as Vector2)-camera_offset
        if _on_screen(p,20.0):
            draw_circle(p,3.0,particle["color"])
    _draw_player(player_pos-camera_offset)
    _draw_world_edge()

func _on_screen(p: Vector2, margin: float) -> bool:
    return p.x > -margin and p.y > -margin and p.x < screen_size.x+margin and p.y < screen_size.y+margin

func _draw_world_edge() -> void:
    var rect: Rect2 = Rect2(-camera_offset,WORLD_SIZE)
    draw_rect(rect,Color("#294d70"),false,4.0)

func _draw_player(p: Vector2) -> void:
    draw_circle(p,28.0,Color(0.15,0.9,1.0,0.12))
    draw_circle(p,PLAYER_RADIUS+3.0,Color("#53e9ff"))
    draw_circle(p,PLAYER_RADIUS,Color("#173451"))
    draw_colored_polygon(PackedVector2Array([p+Vector2(0,-20),p+Vector2(14,12),p+Vector2(0,8),p+Vector2(-14,12)]),Color("#b5fbff"))
    draw_circle(p+Vector2(0,-5),6.0,Color("#5df6ff"))
    draw_line(p,p+mouse_aim*32.0,Color("#a7fbff"),3.0)
    draw_rect(Rect2(p+Vector2(-24,-36),Vector2(48,5)),Color("#44253e"),true)
    draw_rect(Rect2(p+Vector2(-24,-36),Vector2(48.0*clampf(player_hp/max_hp,0.0,1.0),5)),Color("#63edb0"),true)

func _draw_enemy(p: Vector2, enemy: Dictionary) -> void:
    var kind: String = str(enemy["kind"])
    var radius: float = float(enemy["radius"])
    var color: Color = Color("#f25787")
    if kind == "ranged":
        color = Color("#b77cff")
    elif kind == "brute":
        color = Color("#ff925f")
    elif kind == "titan":
        color = Color("#ff3f65")
    if float(enemy["hit"]) > 0.0:
        color = Color.WHITE
    draw_circle(p,radius+8.0,Color(color.r,color.g,color.b,0.12))
    if kind == "titan":
        draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius*0.9,-radius*0.35),p+Vector2(radius*0.8,radius*0.65),p+Vector2(0,radius),p+Vector2(-radius*0.8,radius*0.65),p+Vector2(-radius*0.9,-radius*0.35)]),color)
        draw_circle(p+Vector2(-12,-6),5.0,Color.WHITE)
        draw_circle(p+Vector2(12,-6),5.0,Color.WHITE)
    else:
        draw_circle(p,radius,color)
        draw_circle(p+Vector2(-5,-3),3.5,Color("#17162b"))
        draw_circle(p+Vector2(5,-3),3.5,Color("#17162b"))
    var bar_w: float = radius*2.4
    draw_rect(Rect2(p+Vector2(-bar_w/2,-radius-12),Vector2(bar_w,4)),Color("#46213b"),true)
    draw_rect(Rect2(p+Vector2(-bar_w/2,-radius-12),Vector2(bar_w*clampf(float(enemy["hp"])/float(enemy["max_hp"]),0.0,1.0),4)),Color("#ff668a"),true)

func _draw_building(p: Vector2, kind: String, decor: bool) -> void:
    if kind == "ruin":
        draw_rect(Rect2(p-Vector2(18,16),Vector2(36,32)),Color("#26354c"),true)
        draw_rect(Rect2(p-Vector2(13,11),Vector2(26,22)),Color("#344960"),false,2.0)
    elif kind == "turret":
        draw_circle(p,23.0,Color(0.2,0.9,1.0,0.13))
        draw_rect(Rect2(p-Vector2(15,15),Vector2(30,30)),Color("#244f70"),true)
        draw_rect(Rect2(p-Vector2(8,8),Vector2(16,16)),Color("#62f5ff"),true)
        draw_line(p,p+Vector2(22,0),Color("#b5fbff"),5.0)
    elif kind == "wall":
        draw_rect(Rect2(p-Vector2(23,12),Vector2(46,24)),Color(0.35,0.8,1.0,0.42),true)
        draw_rect(Rect2(p-Vector2(23,12),Vector2(46,24)),Color("#72dfff"),false,2.0)
    elif kind == "refinery":
        draw_rect(Rect2(p-Vector2(18,18),Vector2(36,36)),Color("#6653a0"),true)
        draw_circle(p,7.0,Color("#c0a6ff"))
        draw_arc(p,23.0,0.0,TAU,24,Color("#bba2ff"),2.0)

func _draw_hud() -> void:
    hud_buttons.clear()
    interact_buttons.clear()
    _draw_panel(Rect2(18,16,380,118),Color(0.035,0.07,0.14,0.91))
    _text("STARFALL  /  SECTOR ZERO",Vector2(34,40),15,Color("#65f4ff"))
    _text("المستوى %d   •   الموجة %d" % [player_level,wave],Vector2(34,66),19,Color.WHITE)
    _draw_bar(Rect2(34,79,260,10),player_hp/max_hp,Color("#67f0b6"))
    _text("HP %d / %d" % [int(player_hp),int(max_hp)],Vector2(304,89),12,Color("#d5e8ff"))
    _draw_bar(Rect2(34,99,260,7),float(xp)/float(maxi(1,xp_next)),Color("#a38cff"))
    _text("XP %d/%d" % [xp,xp_next],Vector2(304,108),12,Color("#d5e8ff"))
    _draw_panel(Rect2(screen_size.x-290,16,272,124),Color(0.035,0.07,0.14,0.91))
    _text("حقيبة الموارد",Vector2(screen_size.x-270,40),16,Color("#e7efff"))
    _text("🟡 خردة %d   💎 بلور %d" % [int(resources["scrap"]),int(resources["crystal"])],Vector2(screen_size.x-270,66),14,Color("#f3d789"))
    _text("▧ ألياف %d   ◈ غاز %d" % [int(resources["fiber"]),int(resources["gas"])],Vector2(screen_size.x-270,90),14,Color("#a8f5e5"))
    _text("سبيكة %d   حيوي %d" % [int(resources["alloy"]),int(resources["bio"])],Vector2(screen_size.x-270,114),14,Color("#d9b9ff"))
    var buttons: Array[Dictionary] = [
        {"id":"collect","label":"جمع","rect":Rect2(18,screen_size.y-92,92,70),"color":Color("#2d8b89")},
        {"id":"medkit","label":"إسعاف %d" % int(inventory.get("medkit",0)),"rect":Rect2(118,screen_size.y-92,104,70),"color":Color("#287a70")},
        {"id":"grenade","label":"قنبلة %d" % int(inventory.get("grenade",0)),"rect":Rect2(230,screen_size.y-92,105,70),"color":Color("#a65b43")},
        {"id":"inventory","label":"الحقيبة","rect":Rect2(screen_size.x-440,screen_size.y-82,90,58),"color":Color("#354b71")},
        {"id":"skills","label":"المهارات","rect":Rect2(screen_size.x-344,screen_size.y-82,90,58),"color":Color("#57458b")},
        {"id":"craft","label":"التصنيع","rect":Rect2(screen_size.x-248,screen_size.y-82,90,58),"color":Color("#376d83")},
        {"id":"quests","label":"المهام","rect":Rect2(screen_size.x-152,screen_size.y-82,64,58),"color":Color("#6b5a37")},
        {"id":"pause","label":"Ⅱ","rect":Rect2(screen_size.x-78,screen_size.y-82,60,58),"color":Color("#45526b")},
        {"id":"build_turret","label":"برج","rect":Rect2(screen_size.x*0.5-100,screen_size.y-82,62,58),"color":Color("#285a77")},
        {"id":"build_wall","label":"حاجز","rect":Rect2(screen_size.x*0.5-32,screen_size.y-82,62,58),"color":Color("#285a77")},
        {"id":"build_refinery","label":"مصفاة","rect":Rect2(screen_size.x*0.5+36,screen_size.y-82,72,58),"color":Color("#554a86")}
    ]
    for b: Dictionary in buttons:
        _button(b["rect"],str(b["label"]),b["color"],true)
        hud_buttons.append(b)
    var boss: Dictionary = {}
    for enemy: Dictionary in enemies:
        if str(enemy["kind"]) == "titan":
            boss = enemy
            break
    if not boss.is_empty():
        _draw_panel(Rect2(screen_size.x*0.33,150,screen_size.x*0.34,34),Color(0.1,0.025,0.08,0.88))
        _text("TITAN  %d / %d" % [int(boss["hp"]),int(boss["max_hp"])],Vector2(screen_size.x*0.33+10,172),13,Color("#ff799c"))
        _draw_bar(Rect2(screen_size.x*0.33+115,160,screen_size.x*0.34-128,12),float(boss["hp"])/float(boss["max_hp"]),Color("#ff507b"))
    _draw_minimap()

func _draw_minimap() -> void:
    var rect: Rect2 = Rect2(screen_size.x-190,screen_size.y-220,170,115)
    _draw_panel(rect,Color(0.025,0.045,0.09,0.86))
    draw_rect(Rect2(rect.position+Vector2(8,8),rect.size-Vector2(16,16)),Color("#0d1c31"),true)
    for enemy: Dictionary in enemies:
        var p: Vector2 = rect.position+Vector2(8,8)+(enemy["pos"] as Vector2)/WORLD_SIZE*(rect.size-Vector2(16,16))
        draw_circle(p,2.5,Color("#ff6489"))
    for b: Dictionary in buildings:
        if not bool(b.get("decor",false)):
            var p: Vector2 = rect.position+Vector2(8,8)+(b["pos"] as Vector2)/WORLD_SIZE*(rect.size-Vector2(16,16))
            draw_circle(p,2.0,Color("#67efff"))
    var pp: Vector2 = rect.position+Vector2(8,8)+player_pos/WORLD_SIZE*(rect.size-Vector2(16,16))
    draw_circle(pp,4.0,Color.WHITE)

func _draw_inventory() -> void:
    _draw_overlay("الحقيبة والمخزون", "الموارد التي تجمعها تبقى معك. استخدم حزمة الإسعاف أو القنابل من أزرار اللعب.")
    var x0: float = screen_size.x*0.25
    var y0: float = 185.0
    var i: int = 0
    for key: String in RESOURCE_KINDS:
        var col: int = i % 3
        var row: int = int(i/3)
        var rect: Rect2 = Rect2(x0+float(col)*220.0,y0+float(row)*82.0,200,64)
        _draw_panel(rect,Color(0.08,0.13,0.23,0.98))
        draw_circle(rect.position+Vector2(25,30),9.0,_resource_color(key))
        _text(str(RESOURCE_NAMES[key]),rect.position+Vector2(45,26),16,Color.WHITE)
        _text(str(resources.get(key,0)),rect.position+Vector2(45,48),14,Color("#8be9ff"))
        i += 1
    _text("ذخيرة معززة: %d ثانية   |   إسعاف: %d   |   قنابل: %d" % [int(buff_time),int(inventory.get("medkit",0)),int(inventory.get("grenade",0))],Vector2(x0,y0+190),17,Color("#dbe6ff"))
    _button(Rect2(screen_size.x*0.5-100,screen_size.y-105,200,55),"إغلاق",Color("#4d5f7b"),true)

func _draw_skills() -> void:
    _draw_overlay("شجرة المهارات", "النقاط المتاحة: %d  •  افتح المهارات الأساسية لفتح الفروع المتقدمة." % skill_points)
    var cols: int = 3
    var card_w: float = minf(280.0,(screen_size.x-100.0)/3.0)
    var card_h: float = 106.0
    var start_x: float = (screen_size.x-(card_w*3+20.0*2.0))*0.5
    var start_y: float = 150.0
    interact_buttons.clear()
    for i: int in range(SKILLS.size()):
        var skill: Dictionary = SKILLS[i]
        var col: int = i%cols
        var row: int = int(i/cols)
        var rect: Rect2 = Rect2(start_x+float(col)*(card_w+20.0),start_y+float(row)*(card_h+12.0),card_w,card_h)
        var id: String = str(skill["id"])
        var level: int = int(skill_levels.get(id,0))
        var can_buy: bool = skill_points >= int(skill["cost"]) and level < int(skill["max"])
        for req: String in skill["requires"]:
            if int(skill_levels.get(req,0)) <= 0:
                can_buy = false
        _draw_panel(rect,Color(0.09,0.15,0.26,0.98) if can_buy else Color(0.055,0.085,0.15,0.98))
        _text(str(skill["name"]),rect.position+Vector2(14,25),17,Color("#73f2ff") if can_buy else Color("#d0d9ee"))
        _text(str(skill["desc"]),rect.position+Vector2(14,49),13,Color("#b9c7de"))
        _text("الرتبة %d/%d • التكلفة %d" % [level,int(skill["max"]),int(skill["cost"])],rect.position+Vector2(14,72),12,Color("#f2d88c"))
        _button(Rect2(rect.end-Vector2(82,36),Vector2(70,27)),"تطوير",Color("#6853a5") if can_buy else Color("#30394d"),can_buy)
        interact_buttons.append({"id":"skill","index":i,"rect":rect.end-Vector2(82,36),"enabled":can_buy})
    _button(Rect2(screen_size.x*0.5-100,screen_size.y-56,200,42),"إغلاق",Color("#4d5f7b"),true)

func _draw_crafting() -> void:
    _draw_overlay("المختبر والتصنيع", "اختر وصفة لصناعة الأدوات أو بناء المنشآت أو ترقية العتاد.")
    var x0: float = screen_size.x*0.5-390.0
    var y0: float = 155.0
    interact_buttons.clear()
    for i: int in range(RECIPES.size()):
        var recipe: Dictionary = RECIPES[i]
        var rect: Rect2 = Rect2(x0+float(i%2)*400.0,y0+float(int(i/2))*92.0,380,78)
        _draw_panel(rect,Color(0.08,0.14,0.25,0.98))
        _text(str(recipe["name"]),rect.position+Vector2(14,24),17,Color("#79f3ff"))
        _text(str(recipe["desc"]),rect.position+Vector2(14,47),13,Color("#c0cee4"))
        var cost_text: String = ""
        var cost: Dictionary = recipe["cost"]
        for key: String in cost:
            if not cost_text.is_empty():
                cost_text += "  "
            cost_text += "%s %d" % [str(RESOURCE_NAMES[key]),int(cost[key])]
        _text(cost_text,rect.position+Vector2(14,66),11,Color("#f0d48a"))
        _button(Rect2(rect.end-Vector2(90,45),Vector2(78,34)),"صنع",Color("#3b7e91"),true)
        interact_buttons.append({"id":"recipe","index":i,"rect":rect.end-Vector2(90,45)})
    _button(Rect2(screen_size.x*0.5-100,screen_size.y-56,200,42),"إغلاق",Color("#4d5f7b"),true)

func _draw_quests() -> void:
    _draw_overlay("المهمات والإنجازات", "أنجز الأهداف لتحصل على نقاط مهارة وائتمانات إضافية.")
    var x0: float = screen_size.x*0.5-330.0
    var y0: float = 165.0
    for i: int in range(QUESTS.size()):
        var quest: Dictionary = QUESTS[i]
        var rect: Rect2 = Rect2(x0,y0+float(i)*74.0,660,60)
        var done: bool = _quest_completed(str(quest["id"]))
        _draw_panel(rect,Color(0.07,0.15,0.22,0.98))
        _text(str(quest["name"]),rect.position+Vector2(16,24),16,Color("#82f2d7") if done else Color.WHITE)
        _text(str(quest["desc"]),rect.position+Vector2(16,45),13,Color("#b8c8df"))
        var progress: int = mini(int(quest["target"]),_quest_progress(quest))
        _text("مكتملة" if done else "%d / %d" % [progress,int(quest["target"])],rect.position+Vector2(535,35),14,Color("#ffe28c"))
    _button(Rect2(screen_size.x*0.5-100,screen_size.y-56,200,42),"إغلاق",Color("#4d5f7b"),true)

func _draw_map() -> void:
    _draw_overlay("خريطة القطاع", "خريطة مصغرة للموقع الحالي والأعداء والمنشآت.")
    var rect: Rect2 = Rect2(screen_size.x*0.5-350,145,700,screen_size.y-220)
    _draw_panel(rect,Color("#0b1830"))
    var inner: Rect2 = rect.grow(-18.0)
    draw_rect(inner,Color("#102642"),true)
    for i: int in range(24):
        var px: float = inner.position.x+rng.randf()*inner.size.x
        var py: float = inner.position.y+rng.randf()*inner.size.y
        draw_circle(Vector2(px,py),rng.randf_range(1.0,3.0),Color(0.25,0.58,0.82,0.35))
    for enemy: Dictionary in enemies:
        var p: Vector2 = inner.position+(enemy["pos"] as Vector2)/WORLD_SIZE*inner.size
        draw_circle(p,4.0,Color("#ff557d"))
    for b: Dictionary in buildings:
        if not bool(b.get("decor",false)):
            var p: Vector2 = inner.position+(b["pos"] as Vector2)/WORLD_SIZE*inner.size
            draw_circle(p,4.0,Color("#5cf1ff"))
    var pp: Vector2 = inner.position+player_pos/WORLD_SIZE*inner.size
    draw_circle(pp,7.0,Color.WHITE)
    _button(Rect2(screen_size.x*0.5-100,screen_size.y-56,200,42),"إغلاق",Color("#4d5f7b"),true)

func _draw_pause() -> void:
    draw_rect(Rect2(Vector2.ZERO,screen_size),Color(0.01,0.02,0.05,0.76),true)
    _center_text("توقفت اللعبة",screen_size.y*0.34,32,Color("#71f4ff"))
    _button(Rect2(screen_size.x*0.5-130,screen_size.y*0.45,260,55),"متابعة",Color("#376d83"),true)
    _button(Rect2(screen_size.x*0.5-130,screen_size.y*0.45+70,260,55),"حفظ التقدم",Color("#57458b"),true)
    _button(Rect2(screen_size.x*0.5-130,screen_size.y*0.45+140,260,55),"القائمة الرئيسية",Color("#6d4a50"),true)

func _draw_game_over() -> void:
    draw_rect(Rect2(Vector2.ZERO,screen_size),Color(0.01,0.01,0.03,0.88),true)
    _center_text("انتهت الرحلة",screen_size.y*0.32,36,Color("#ff668a"))
    _center_text("وصلت إلى الموجة %d  •  قتلات %d  •  مستوى %d" % [wave,total_kills,player_level],screen_size.y*0.42,19,Color.WHITE)
    _button(Rect2(screen_size.x*0.5-140,screen_size.y*0.52,280,60),"إعادة المحاولة",Color("#397e8f"),true)
    _button(Rect2(screen_size.x*0.5-140,screen_size.y*0.52+75,280,60),"تحميل الحفظ",Color("#57458b"),true)

func _draw_overlay(title: String, subtitle: String) -> void:
    draw_rect(Rect2(Vector2.ZERO,screen_size),Color(0.01,0.025,0.06,0.82),true)
    _draw_panel(Rect2(screen_size.x*0.5-470,50,940,screen_size.y-100),Color(0.035,0.065,0.12,0.98))
    _center_text(title,82,25,Color("#65f4ff"))
    _center_text(subtitle,112,13,Color("#c5d4ea"))

func _draw_toast() -> void:
    var rect: Rect2 = Rect2(screen_size.x*0.5-260,screen_size.y-150,520,38)
    _draw_panel(rect,Color(0.02,0.08,0.13,0.94))
    _center_text(toast,rect.position.y+24,15,Color("#d8faff"))

func _draw_panel(rect: Rect2, color: Color) -> void:
    draw_rect(rect,color,true)
    draw_rect(rect,Color(0.35,0.58,0.77,0.42),false,1.3)

func _button(rect: Rect2, label: String, color: Color, enabled: bool) -> void:
    var final_color: Color = color if enabled else Color(0.15,0.19,0.26,0.85)
    draw_rect(rect,final_color,true)
    draw_rect(rect,Color(0.55,0.86,1.0,0.45),false,1.0)
    _center_text(label,rect.position.y+rect.size.y*0.5+5.0,14,Color.WHITE if enabled else Color("#78869d"))

func _draw_bar(rect: Rect2, value: float, color: Color) -> void:
    draw_rect(rect,Color("#28334a"),true)
    draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(value,0.0,1.0),rect.size.y)),color,true)

func _text(value: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _center_text(value: String, y: float, size: int, color: Color) -> void:
    var font: Font = ThemeDB.fallback_font
    var width: float = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
    draw_string(font,Vector2((screen_size.x-width)*0.5,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
            if _is_overlay_open():
                _close_overlays()
            else:
                paused = not paused
        elif event.keycode == KEY_E:
            _collect_nearby()
        elif event.keycode == KEY_I:
            show_inventory = not show_inventory
        elif event.keycode == KEY_K:
            show_skills = not show_skills
        elif event.keycode == KEY_C:
            show_crafting = not show_crafting
        elif event.keycode == KEY_J:
            show_quests = not show_quests
        elif event.keycode == KEY_M:
            show_map = not show_map
        elif event.keycode == KEY_F5:
            _save_game()
        elif event.keycode == KEY_H:
            _use_medkit()
        elif event.keycode == KEY_G:
            _use_grenade()
        elif event.keycode == KEY_SPACE:
            _fire_at_nearest()
    if event is InputEventMouseButton and event.pressed:
        _handle_press(event.position)
    elif event is InputEventScreenTouch:
        if event.pressed:
            _handle_press(event.position)
            touch_id = event.index
            if event.position.x < screen_size.x*0.35 and event.position.y > screen_size.y*0.42:
                touch_origin = event.position
                touch_move = Vector2.ZERO
            elif event.position.x > screen_size.x*0.72 and event.position.y < screen_size.y*0.72:
                fire_touch = true
        else:
            if event.index == touch_id:
                touch_move = Vector2.ZERO
                touch_id = -999
            if event.position.x > screen_size.x*0.72:
                fire_touch = false
    elif event is InputEventScreenDrag:
        if event.index == touch_id and touch_origin != Vector2.ZERO:
            touch_move = (event.position-touch_origin).limit_length(1.0)
            if touch_move.length() > 0.15:
                mouse_aim = touch_move.normalized()
        elif event.position.x > screen_size.x*0.72 and event.position.y < screen_size.y*0.72:
            fire_touch = true

func _handle_press(pos: Vector2) -> void:
    if game_over:
        if _point_in(pos,Rect2(screen_size.x*0.5-140,screen_size.y*0.52,280,60)):
            _restart_game()
        elif _point_in(pos,Rect2(screen_size.x*0.5-140,screen_size.y*0.52+75,280,60)):
            game_over = false
            _load_game()
        return
    if paused:
        if _point_in(pos,Rect2(screen_size.x*0.5-130,screen_size.y*0.45,260,55)):
            paused = false
        elif _point_in(pos,Rect2(screen_size.x*0.5-130,screen_size.y*0.45+70,260,55)):
            _save_game()
        elif _point_in(pos,Rect2(screen_size.x*0.5-130,screen_size.y*0.45+140,260,55)):
            paused = false
            _close_overlays()
            _restart_game()
        return
    if show_skills:
        for b: Dictionary in interact_buttons:
            if _point_in(pos,b["rect"]):
                _buy_skill(int(b["index"]))
                return
        if pos.y > screen_size.y-65.0:
            show_skills = false
        return
    if show_crafting:
        for b: Dictionary in interact_buttons:
            if _point_in(pos,b["rect"]):
                _craft(RECIPES[int(b["index"])])
                return
        if pos.y > screen_size.y-65.0:
            show_crafting = false
        return
    if show_inventory or show_quests or show_map:
        if pos.y > screen_size.y-115.0 or pos.x > screen_size.x-150.0:
            _close_overlays()
        return
    for b: Dictionary in hud_buttons:
        if _point_in(pos,b["rect"]):
            _activate_button(str(b["id"]))
            return
    if pos.x > screen_size.x*0.38 and pos.y < screen_size.y-100.0:
        var world_pos: Vector2 = pos+camera_offset
        var dir: Vector2 = world_pos-player_pos
        if dir.length() > 5.0:
            mouse_aim = dir.normalized()
            if fire_cooldown <= 0.0:
                _fire_at_nearest()

func _activate_button(id: String) -> void:
    match id:
        "collect": _collect_nearby()
        "medkit": _use_medkit()
        "grenade": _use_grenade()
        "inventory":
            show_inventory = true
            _close_other_than("inventory")
        "skills":
            show_skills = true
            _close_other_than("skills")
        "craft":
            show_crafting = true
            _close_other_than("craft")
        "quests":
            show_quests = true
            _close_other_than("quests")
        "pause": paused = true
        "build_turret": _place_building("turret")
        "build_wall": _place_building("wall")
        "build_refinery": _place_building("refinery")

func _close_other_than(keep: String) -> void:
    if keep != "inventory": show_inventory = false
    if keep != "skills": show_skills = false
    if keep != "craft": show_crafting = false
    if keep != "quests": show_quests = false
    if keep != "map": show_map = false

func _point_in(point: Vector2, rect: Rect2) -> bool:
    return rect.has_point(point)

func _restart_game() -> void:
    player_pos = WORLD_SIZE*0.5
    player_hp = 100.0
    max_hp = 100.0
    player_level = 1
    xp = 0
    xp_next = 40
    skill_points = 0
    resources = {"scrap":25,"crystal":5,"fiber":8,"gas":2,"alloy":0,"bio":3}
    inventory = {"medkit":1,"grenade":0,"ammo_buff":0}
    weapon_damage = 18.0
    wave = 1
    wave_timer = 18.0
    total_kills = 0
    total_builds = 0
    total_bosses = 0
    quest_flags.clear()
    _init_skill_levels()
    enemies.clear()
    bullets.clear()
    drops.clear()
    particles.clear()
    _spawn_world()
    _spawn_wave(true)
    game_over = false
    _close_overlays()
    _notify("بدأت رحلة جديدة")

func _draw_input_help() -> void:
    pass
