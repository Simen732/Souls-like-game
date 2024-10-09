extends Node


const SPEED = 5.0
const JUMP_VELOCITY = 5

#-----------------------------------------------------------------------------------------------------#

var player_position = 0
var maxStamina = 200
var maxHealth = 100
var idkKerft = true
var Menu_open = false
var spawnPoint = Vector3(0,0,0)
var deathCount = 0
var runSpeed = 2
var playerIsDying = false
var dogdeSpeed = 10
var dodgeCooldown = 45
var Iframes = 20
var isDodging = false
var dashStartTime = 0.0
var dashDuration = 0.5
var dashDirection = Vector3.ZERO
var weaponDamage = 10
var SkillPoints = 1
var attackTimer = 0
var isAttacking = false
var isRunning = false
var enemyIFrames = 0


var isFightingBoss = false
var biGayHealth = 200
