import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.KeyboardEvent;
import haxe.ds.StringMap;

class Main {
    public static var canvas:CanvasElement;
    public static var ctx:CanvasRenderingContext2D;
    public static var width:Int = 640;
    public static var height:Int = 480;
    public static var keys:StringMap<Bool> = new StringMap<Bool>();
    public static var player:Player;
    public static var bullets:Array<Bullet> = [];
    public static var enemies:Array<Enemy> = [];
    public static var score:Int = 0;
    public static var lives:Int = 3;
    public static var gameOver:Bool = false;
    public static var lastShoot:Float = 0;
    public static var lastEnemySpawn:Float = 0;
    public static var spawnRate:Float = 1.0;
    public static var prevTime:Float = 0;

    static public function main() {
        var doc = Browser.document;
        canvas = cast doc.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        canvas.style.border = "2px solid #333";
        canvas.style.backgroundColor = "#000";
        doc.body.style.margin = "0";
        doc.body.style.overflow = "hidden";
        doc.body.style.backgroundColor = "#111";
        doc.body.appendChild(canvas);
        ctx = cast canvas.getContext("2d");
        player = new Player(width / 2, height - 40);
        Browser.window.addEventListener("keydown", onKeyDown);
        Browser.window.addEventListener("keyup", onKeyUp);
        Browser.window.requestAnimationFrame(frame);
    }

    static function onKeyDown(event:KeyboardEvent):Void {
        // 一部ブラウザで key が undefined になることがあるので null 安全に扱う
        var k = event.key == null ? "" : event.key;
        keys.set(k, true);
        if (k == " " || k == "Spacebar") event.preventDefault();
    }

    static function onKeyUp(event:KeyboardEvent):Void {
        var k = event.key == null ? "" : event.key;
        keys.set(k, false);
    }

    static function frame(timestamp:Float):Void {
        var now = timestamp / 1000;
        var delta = if (prevTime == 0) 0 else now - prevTime;
        prevTime = now;
        if (!gameOver) update(delta, now);
        render();
        Browser.window.requestAnimationFrame(frame);
    }

    static function update(delta:Float, now:Float):Void {
        if (keys.exists("ArrowLeft") && keys.get("ArrowLeft")) player.x -= player.speed * delta;
        if (keys.exists("ArrowRight") && keys.get("ArrowRight")) player.x += player.speed * delta;
        if (keys.exists("a") && keys.get("a")) player.x -= player.speed * delta;
        if (keys.exists("d") && keys.get("d")) player.x += player.speed * delta;
        if (keys.exists(" ") && keys.get(" ")) player.tryShoot(now);
        if (keys.exists("ArrowUp") && keys.get("ArrowUp")) player.tryShoot(now);

        if (player.x < 20) player.x = 20;
        if (player.x > width - 20) player.x = width - 20;

        for (bullet in bullets) bullet.update(delta);
        bullets = bullets.filter(function(b) return !b.dead);

        if (now - lastEnemySpawn >= spawnRate) {
            enemies.push(Enemy.create());
            lastEnemySpawn = now;
            spawnRate = Math.max(0.35, spawnRate - 0.01);
        }

        for (enemy in enemies) enemy.update(delta);
        enemies = enemies.filter(function(e) return !e.dead);

        for (enemy in enemies) {
            if (!enemy.dead && enemy.hitPlayer(player)) {
                enemy.dead = true;
                lives -= 1;
                if (lives <= 0) gameOver = true;
            }
            for (bullet in bullets) {
                if (!enemy.dead && !bullet.dead && enemy.hitPoint(bullet.x, bullet.y)) {
                    enemy.dead = true;
                    bullet.dead = true;
                    score += 10;
                }
            }
        }
    }

    static function render():Void {
        ctx.fillStyle = "#05050d";
        ctx.fillRect(0, 0, width, height);
        ctx.fillStyle = "#0f7";
        ctx.font = "16px Arial";
        ctx.fillText("SCORE: " + score, 16, 24);
        ctx.fillText("LIVES: " + lives, width - 110, 24);

        if (gameOver) {
            ctx.fillStyle = "#f44";
            ctx.font = "52px Arial";
            ctx.fillText("GAME OVER", width / 2 - 160, height / 2 - 20);
            ctx.font = "18px Arial";
            ctx.fillText("Refresh to play again", width / 2 - 110, height / 2 + 20);
            return;
        }

        player.draw(ctx);
        for (bullet in bullets) bullet.draw(ctx);
        for (enemy in enemies) enemy.draw(ctx);

        ctx.fillStyle = "#fff";
        ctx.font = "14px Arial";
        ctx.fillText("arrows / A D = move, space = shoot", 16, height - 16);
    }
}

class Player {
    public var x:Float;
    public var y:Float;
    public var speed:Float = 280;
    public var radius:Float = 18;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    public function tryShoot(now:Float):Void {
        if (now - Main.lastShoot >= 0.22) {
            Main.lastShoot = now;
            Main.bullets.push(new Bullet(x, y - radius - 8));
        }
    }

    public function draw(ctx:CanvasRenderingContext2D):Void {
        ctx.fillStyle = "#4af";
        ctx.beginPath();
        ctx.moveTo(x, y - radius);
        ctx.lineTo(x - 18, y + 14);
        ctx.lineTo(x + 18, y + 14);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = "#7df";
        ctx.fillRect(x - 6, y - radius + 4, 12, 12);
    }
}

class Bullet {
    public var x:Float;
    public var y:Float;
    public var speed:Float = 420;
    public var dead:Bool = false;

    public function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    public function update(delta:Float):Void {
        y -= speed * delta;
        if (y < -10) dead = true;
    }

    public function draw(ctx:CanvasRenderingContext2D):Void {
        ctx.fillStyle = "#fff";
        ctx.fillRect(x - 2, y - 8, 4, 12);
    }
}

class Enemy {
    public var x:Float;
    public var y:Float;
    public var speed:Float;
    public var radius:Float;
    public var dead:Bool = false;

    public function new(x:Float, y:Float, speed:Float, radius:Float) {
        this.x = x;
        this.y = y;
        this.speed = speed;
        this.radius = radius;
    }

    public static function create():Enemy {
        var radius = 14 + Math.random() * 10;
        var x = radius + Math.random() * (Main.width - radius * 2);
        return new Enemy(x, -radius - 10, 60 + Math.random() * 80, radius);
    }

    public function update(delta:Float):Void {
        y += speed * delta;
        if (y > Main.height + radius) dead = true;
    }

    public function draw(ctx:CanvasRenderingContext2D):Void {
        ctx.fillStyle = "#f76";
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = "#fee";
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    public function hitPoint(px:Float, py:Float):Bool {
        return Math.sqrt((px - x) * (px - x) + (py - y) * (py - y)) < radius + 4;
    }

    public function hitPlayer(player:Player):Bool {
        return Math.sqrt((player.x - x) * (player.x - x) + (player.y - y) * (player.y - y)) < radius + player.radius - 2;
    }
}
