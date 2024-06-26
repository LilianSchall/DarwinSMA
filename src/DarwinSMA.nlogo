globals
[
  ; variables used to show statistics
  ; the mean of each represented genes
  mean-speed
  mean-creature-size
  mean-sense

  ; the number of individuals where the dominant gene is xx
  nb-dominant-speed
  nb-dominant-creature-size
  nb-dominant-sense

  ; the number of eaten individuals
  nb-eaten-creatures-stat
  nb-eaten-creatures

  ; the number of eaten grass
  nb-eaten-grass-stat
  nb-eaten-grass
]


breed [creatures creature]

creatures-own
[
  ; creatures are characterized by their
  ; speed, size and size.
  speed
  creature-size
  sense

  ; those properties are used for ongoing generation
  energy
  nb-food-taken
]

to init
   __clear-all-and-reset-ticks
  init-patches
  init-creatures nb-creatures
end

to init-patches
  ; generate food randomly in the world
  ask n-of nb-food patches with [count neighbors = 8] [
    set pcolor green
  ]
end

to init-creatures [nb]
  ; create creatures at the edge of the world
  ; facing towards the center
  create-creatures nb
  [
    set shape "person"
    set color white
    move-to one-of patches with ; simply said:
    [
      count neighbors < 8 and   ; place the creatures at the edge of the world
      not any? turtles-here     ; where no creature has been place yet
    ]
    face patch 0 0 ; face towards the center

    set speed 1
    set creature-size 1
    set size creature-size
    set sense nb-init-sense

    set energy nb-init-energy
    set nb-food-taken 0
  ]
end

to go
  ; for each tick, we move the creature, eat if necessary
  move-creatures

  ; whenever no creature can move, it's the end of the generation
  ; so let's launch the next generation
  if (count creatures with [energy > 0]) = 0 [
    ; first we update stats for the generation
    update-stats

    next-generation
  ]

  if (count creatures) = 0 [
    ; There are no creatures left at all
    ; We can stop the simulation
    stop
  ]

  tick
end

to update-stats
  ifelse any? creatures
  [
    ; Update the mean values of each genes
    set mean-speed mean [speed] of creatures
    set mean-creature-size mean [creature-size] of creatures
    set mean-sense mean [sense] of creatures

    ; Reset counters for dominant genes for the next generation
    set nb-dominant-speed 0
    set nb-dominant-creature-size 0
    set nb-dominant-sense 0

    ; Update the food eaten stats
    set nb-eaten-creatures-stat nb-eaten-creatures
    set nb-eaten-grass-stat nb-eaten-grass

    ; Reset counters for food eaten for the next generation
    set nb-eaten-creatures 0
    set nb-eaten-grass 0

    ; For each creature, determine the dominant trait and increment the respective counter
    ask creatures [
      let dominant-trait (max (list (speed - 1) (creature-size - 1) (sense - nb-init-sense)))
      ifelse (dominant-trait = (creature-size - 1)) [
        set nb-dominant-creature-size nb-dominant-creature-size + 1
      ]
      [
        ifelse (dominant-trait = (sense - nb-init-sense)) [
          set nb-dominant-sense nb-dominant-sense + 1
        ]
        [
          if (dominant-trait = (speed - 1)) [
            set nb-dominant-speed nb-dominant-speed + 1
          ]
        ]
      ]
    ]
  ]
  [
    set mean-speed 0
    set mean-creature-size 0
    set mean-sense 0
    set nb-dominant-speed 0
    set nb-dominant-creature-size 0
    set nb-dominant-sense 0
  ]
end

to move-creatures
  ask creatures with [energy > 0] ; only give life to creatures
  [                               ; who still got energy left
    if pcolor = green and nb-food-taken < 2 [eat-grass] ; if we are on food, eat it
    move-primitive
    set energy (energy - (speed * speed * creature-size * creature-size * creature-size + sense))
    if (patch-ahead 1) = nobody [set energy 0]
  ]
end

to move-primitive
  ; find the different closest foods (green patch, creature smaller by 20+%) and threats (creature bigger by 20+%) in the sense radius
  let closest-food min-one-of patches with [pcolor = green] in-radius sense [distance myself]
  let closest-small-turtle min-one-of turtles with [size <= [size] of myself * 0.8] in-radius sense [distance myself]
  let closest-big-turtle min-one-of turtles with [size >= [size] of myself * 1.2] in-radius sense [distance myself]

  ; set the target based on the closest food if it has less than 2 food
  let closest-target nobody
  if closest-food != nobody and nb-food-taken < 2
  [
    set closest-target closest-food
  ]
  if closest-small-turtle != nobody and nb-food-taken < 2
  [
    if closest-target = nobody or [distance myself] of closest-small-turtle < [distance myself] of closest-target
    [
      set closest-target closest-small-turtle
    ]
  ]
  ; if there is a threat, check if it is the closest
  ifelse closest-big-turtle != nobody
  [
    if closest-target = nobody or [distance myself] of closest-big-turtle < [distance myself] of closest-target
    [
      ; Face away from the threat and move away
      face closest-big-turtle
      rt 180
    ]
    fd speed
  ]
  [
    ifelse closest-target != nobody
    [
      face closest-target
      let d distance closest-target
      fd min list d speed
      if any? other turtles-here [eat-creature] ; we eat a smaller creature here so it can't get away
    ]
    [
      fd speed
    ]
  ]

end

to eat-grass
  set pcolor black
  set nb-food-taken (nb-food-taken + 1)
  set nb-eaten-grass (nb-eaten-grass + 1) ; Increment the counter
  face min-one-of (patches with ; go to the nearest edge
    [
      count neighbors < 8 and
      not any? turtles-here
    ]) [distance myself]
end

to eat-creature
  let smaller-creatures other turtles-here with [size < [size] of myself * 0.8]
  if any? smaller-creatures
  [
    ask one-of smaller-creatures
    [
      die
    ]
    set nb-food-taken (nb-food-taken + 1)
    set nb-eaten-creatures (nb-eaten-creatures + 1) ; Increment the counter
    face min-one-of (patches with ; go to the nearest edge
    [
      count neighbors < 8 and
      not any? turtles-here
    ]) [distance myself]
  ]
end


to next-generation
  clear-patches
  clear-creatures-not-at-home
  reproduce-creatures-with-mutation
  reset-creatures
  update-creatures-color
  init-patches
end

to clear-creatures-not-at-home
  ; creatures that are not at the edge of the world or that haven't eaten must die
  ask creatures with [count neighbors >= 8 or nb-food-taken = 0] [
    die
  ]
end

to reproduce-creatures ; unused
  let nb-offsprings (count creatures with [nb-food-taken >= 2])
  init-creatures nb-offsprings
  ask creatures [
    set energy nb-init-energy
    set nb-food-taken 0
    face patch 0 0 ; face towards the center
  ]
end

to reproduce-creatures-with-mutation
  ask creatures with [nb-food-taken >= 2] [
    let mutate-speed (mutation 0.1)
    let mutate-size (mutation 0.1)
    let mutate-sense (mutation 0.1)

    hatch 1 [
      set creature-size (max list 0.1 (creature-size + mutate-size))
      set speed (max list 0.1 (speed + mutate-speed))
      set sense (max list 0.1 (sense + mutate-sense))
    ]
  ]
end

to-report mutation [value]
  let random-value  2 * (random 100) - 100
  ifelse (random-value >= (-(proba-mutation) * 100) and random-value < 0)
  [
    report (-(value))
  ]
  [
    ifelse (random-value >= 0 and random-value < proba-mutation * 100)
    [
      report value
    ]
    [
      report 0
    ]
  ]
end

to reset-creatures
    ask creatures [
    set energy nb-init-energy
    set nb-food-taken 0
    face patch 0 0 ; face towards the center
    set size creature-size
  ]
end

to update-creatures-color
  ask creatures [
    if (max (list (speed - 1) (sense - nb-init-sense) (creature-size - 1))) = (speed - 1) [ set color blue]
    if (max (list (speed - 1) (sense - nb-init-sense) (creature-size - 1))) = (sense - nb-init-sense) [ set color red]
    if (max (list (speed - 1) (sense - nb-init-sense) (creature-size - 1))) = (creature-size - 1) [ set color yellow]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
268
10
924
667
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
179
59
242
92
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
36
59
165
92
NIL
init
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
40
248
212
281
nb-creatures
nb-creatures
1
50
50.0
1
1
NIL
HORIZONTAL

SLIDER
41
301
213
334
nb-food
nb-food
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
39
475
211
508
nb-init-energy
nb-init-energy
10
1000
500.0
10
1
NIL
HORIZONTAL

SLIDER
39
512
211
545
nb-init-sense
nb-init-sense
1
10
5.0
1
1
NIL
HORIZONTAL

PLOT
30
602
230
752
nb-creatures
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count creatures"

SLIDER
40
415
212
448
proba-mutation
proba-mutation
0.1
1
1.0
0.1
1
NIL
HORIZONTAL

PLOT
979
10
1392
206
Means of genes
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"speed" 1.0 0 -13345367 true "" "plot mean-speed"
"sense" 1.0 0 -2674135 true "" "plot mean-sense"
"size" 1.0 0 -1184463 true "" "plot mean-creature-size"

PLOT
973
218
1400
424
Dominant genes
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"speed" 1.0 0 -13345367 true "" "plot nb-dominant-speed"
"sense" 1.0 0 -2674135 true "" "plot nb-dominant-sense"
"size" 1.0 0 -1184463 true "" "plot nb-dominant-creature-size"

PLOT
974
437
1409
623
Food
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"cannibalism" 1.0 0 -2674135 true "" "plot nb-eaten-creatures-stat"
"grass" 1.0 0 -10899396 true "" "plot nb-eaten-grass-stat"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghost
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="calcul Scales sensitivity" repetitions="10" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="2500"/>
    <metric>count individus with [infecte?]</metric>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proba-infection">
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="signature proba_infection_100-2" repetitions="100" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="2500"/>
    <metric>count individus with [infecte? ]</metric>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proba-infection" first="0.1" step="0.01" last="1"/>
    <enumeratedValueSet variable="distance-infection">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity2" repetitions="10" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="2500"/>
    <metric>count individus with [infecte?]</metric>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="1.5"/>
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="1.5"/>
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proba-infection">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test_lecon" repetitions="10" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="2500"/>
    <metric>count individus with [infecte?]</metric>
    <enumeratedValueSet variable="proba-infection">
      <value value="0.13"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dist-max-deplacement" first="1" step="0.5" last="3"/>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="proba-infection">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="signature_lecon_proba_infection" repetitions="10" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="1000"/>
    <metric>count individus with [ infecte?]</metric>
    <enumeratedValueSet variable="nb-individus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="proba-infection" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="distance-perception">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MAPSCours" repetitions="10" runMetricsEveryStep="false">
    <setup>init-simulation</setup>
    <go>pas-simulation</go>
    <timeLimit steps="2500"/>
    <metric>count individus with [infecte?]</metric>
    <enumeratedValueSet variable="proba-infection">
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taux-infectes-init">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-perception">
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dist-max-deplacement">
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-infection">
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
