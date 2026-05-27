# 🧊 3D Avatar System — Future Roadmap (Version 3.0)

This document explains how the current 2D avatar system is designed
to transition into a 3D avatar preview in Version 3.0.

---

## Current 2D Avatar System (v1.x)

The `AvatarConfig` dictionary (managed by `AvatarManager.gd`) stores:

```gdscript
{
    "body_type":    "default",      # Body proportions
    "skin_tone":    "medium",       # One of 7 skin tones
    "hairstyle":    "default_hair", # Item ID of hairstyle
    "hair_color":   "#4A2800",      # Hex color string
    "outfit":       "sparkle_shirt",# Item ID of outfit
    "shoes":        "pink_sneakers",# Item ID of shoes
    "accessory":    "star_hair_clip",# Item ID of accessory
    "special_effect": "",           # Rare item effect
    "equipped_items": [...]         # List of all equipped IDs
}
```

---

## How 2D Avatars Map to 3D

Each 2D avatar slot maps to a 3D counterpart:

| 2D Avatar Field | 3D Equivalent               |
|-----------------|-----------------------------|
| `body_type`     | Character mesh variant      |
| `skin_tone`     | Material skin color         |
| `hairstyle`     | Hair mesh attachment        |
| `hair_color`    | Hair material color         |
| `outfit`        | Clothing mesh (top/full body)|
| `shoes`         | Shoe mesh attachment        |
| `accessory`     | Accessory mesh (clip, bag)  |
| `special_effect`| Particle system or shader   |

---

## Version 3.0 — Implementation Plan

### Step 1: Create the 3D Avatar Preview Scene

Create a new scene: `scenes/avatar/AvatarPreview3D.tscn`

```
Node3D (root)
├── SubViewportContainer       ← Shows 3D in a 2D UI window
│   └── SubViewport
│       ├── Camera3D           ← Points at the avatar
│       ├── DirectionalLight3D
│       └── AvatarRoot (Node3D)
│           ├── CharacterModel (MeshInstance3D)
│           │   ├── Skeleton3D ← Animation rig
│           │   ├── HairSlot   ← Hair mesh goes here
│           │   ├── OutfitSlot ← Clothing mesh goes here
│           │   ├── ShoeSlot   ← Shoe mesh goes here
│           │   └── AccessorySlot
│           └── AnimationPlayer← Idle rotation, idle animation
├── RotateLeftButton (Button)
└── RotateRightButton (Button)
```

### Step 2: Base Character Model

Use a simple low-poly humanoid model (recommended sources):
- **Quaternius Poly Folks** (CC0): https://quaternius.com
- **Kenney Character Pack** (CC0): https://kenney.nl
- Or commission a simple rigged character

The model should have:
- A **Skeleton3D** with standard humanoid bones
- **Blend shapes** (morph targets) for body type variation
- Modular **attachment points** for clothing and accessories

### Step 3: Clothing as Separate Meshes

Each clothing item is a separate `MeshInstance3D` that:
- Attaches to the correct bone (e.g., outfit attaches to Spine bone)
- Has its own material for color customization
- Can be shown/hidden by the avatar system

```gdscript
# In AvatarPreview3D.gd
func equip_outfit(outfit_id: String) -> void:
    var config := AvatarManager.get_config()
    # Load the 3D mesh for this outfit
    var mesh_path := "res://assets/3d/clothing/%s.glb" % outfit_id
    if ResourceLoader.exists(mesh_path):
        var mesh_instance := MeshInstance3D.new()
        mesh_instance.mesh = load(mesh_path)
        outfit_slot.add_child(mesh_instance)
```

### Step 4: Material-Based Color Customization

Skin tone and hair color use Godot 4's `StandardMaterial3D`:

```gdscript
func set_skin_tone(tone: String) -> void:
    var skin_colors := {
        "light": Color(1.0, 0.87, 0.73),
        "medium": Color(0.8, 0.60, 0.35),
        "dark": Color(0.35, 0.22, 0.10),
        # ...
    }
    var material := character_mesh.get_surface_override_material(0)
    if material:
        material.albedo_color = skin_colors.get(tone, Color.WHITE)
```

### Step 5: Avatar Rotation Preview

Allow the player to rotate the 3D avatar to see all sides:

```gdscript
# In AvatarPreview3D.gd
var _rotation_speed: float = 60.0  # Degrees per second
var _is_rotating: bool = false

func _process(delta: float) -> void:
    if _is_rotating:
        avatar_root.rotate_y(deg_to_rad(_rotation_speed * delta))

func _on_rotate_button_pressed() -> void:
    _is_rotating = not _is_rotating
```

### Step 6: Sync with Existing AvatarConfig

The 3D preview reads from the **same** `AvatarConfig` as the 2D system:

```gdscript
func _ready() -> void:
    # Load current avatar config (same data used by 2D system)
    var config := AvatarManager.get_config()
    apply_config(config)
    
    # Listen for changes
    AvatarManager.avatar_updated.connect(apply_config)

func apply_config(config: Dictionary) -> void:
    set_skin_tone(config.get("skin_tone", "medium"))
    set_hair_color(config.get("hair_color", "#4A2800"))
    equip_outfit(config.get("outfit", "default_outfit"))
    equip_shoes(config.get("shoes", "default_shoes"))
    equip_accessory(config.get("accessory", ""))
```

---

## Data Compatibility Promise

The `AvatarConfig` structure used in v1.x is **designed to be forward-compatible**.

When v3.0 is implemented:
- The **same save file** will work for both 2D and 3D
- The same `AvatarManager` singleton will serve both systems
- No data migration will be needed
- Items purchased in the store will automatically appear in the 3D closet

---

## Recommended 3D Tools

| Tool | Purpose |
|------|---------|
| Blender (free) | Model and rig characters |
| Godot's GLB importer | Import `.glb` files from Blender |
| Quaternius assets | Free pre-made characters |
| Godot ShaderMaterial | Custom visual effects (sparkle, glow) |

---

## Timeline

| Version | Feature |
|---------|---------|
| 1.x | 2D avatar closet (current) |
| 2.x | More avatar items, more variety |
| 3.0 | 3D preview room (in AvatarCloset only) |
| 3.x | Full 3D character in gameplay |

---

*This document is a living guide. Update it as decisions are made.*
