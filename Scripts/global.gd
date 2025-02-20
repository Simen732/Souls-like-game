extends Node

signal restart
signal playerTakeDamage
signal playerDealDamage

#-----------------------------------------------------------------------------------------------------#

const SPEED = 5.0
const JUMP_VELOCITY = 7.5

#-----------------------------------------------------------------------------------------------------#

var player_position = 0
var enemy_lock_on_position = 0
var maxStamina = 300
var maxHealth = 200
var Menu_open = false
var spawnPoint = Vector3(0,0,0)
var deathCount = 0
var runSpeed = 2
var playerIsDying = false
var dogdeSpeed = 10
var dodgeCooldown = 45
var Iframes = 30
var isDodging = false
var dashStartTime = 0.0
var dashDuration = 1
var dashboost = 0
var dashDirection = Vector3.ZERO
var weaponDamage = 10
var SkillPoints = 100
var isAttacking = false
var isRunning = false
var enemyIFrames = 0
var flinch = false
var Spirit = 0
var locked_on = false
var havePlayedGame = false

var enemiesGettingHit = []
var isFighting = false

