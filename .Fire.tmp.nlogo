;; Base fire model adapted and enhanced by: Adam Dzadon & Martin Tucek ( Masaryk's University )

globals [
  initial-trees         ;; how many trees (green patches) we started with
  burned-trees          ;; how many have burned so far

  opposite-prob         ;; probability that the tree which grows in the opposite direction of the wind will ignite
  wind-prob             ;; probability that the tree which grows in the direction of the wind will ignite
  default-prob          ;; probability that the tree will ignite (is not influenced with wind direction)

  opposite-spread       ;; per what amount of ticks to spread fire in the opposite direction of the wind
  wind-spread           ;; per what amount of ticks to spread fire in non-wind direction
  default-spread        ;; per what amount of tick to spread fire in wind direction

  spread-lcm            ;; lowest common multiple of spread values ( it servers as fading rate )

  extinguish-radius     ;; Radius of water-drop inpact
  extinguish-rate       ;; once per WHAT amount of ticks will the water be dropped

  dropped-water         ;; total amount of "cyan" cells (the cells where the water was dropped)
  extinguishing-water   ;; amount of water which was not thrown at burning tree

]

breed [fires fire]    ;; bright red turtles -- the leading edge of the fire
breed [embers ember]  ;; turtles gradually fading from red to near black

to-report gcd [a b]
  ifelse b = 0
    [report a]
    [report gcd b (a mod b)]
end

to-report lcm [a b]
  report (a * b) / (gcd a b)
end

;; function to initializes the automaton
to setup
  clear-all
  set-default-shape turtles "square"
  ;; make some green trees
  ask patches with [(random-float 100) < density]
    [ set pcolor green ]

  ;; We make fire to start at the center of our forest
  center-init-fire 60
  ;; set tree counts
  set initial-trees count patches with [pcolor = green]
  set burned-trees 0

  ;; --- Global variable settings

  set wind-prob 100
  let standard-velocity wind-velocity / 100

  set default-prob wind-prob - wind-prob * standard-velocity / 4

  ;; probabilty that the fire will spread in the opposite direction of wind
  set opposite-prob wind-prob - wind-prob * standard-velocity

  let base-spread 5
  set wind-spread round ( base-spread - standard-velocity * (base-spread - 1) )
  set default-spread round (base-spread - standard-velocity  / 4 * (base-spread - 1) )
  set opposite-spread base-spread

  if ( wind-direction = "None" )
  [
  set wind-spread base-spread
  set default-spread base-spread
  set opposite-spread base-spread
  ]

  set spread-lcm lcm (lcm wind-spread default-spread) opposite-spread

  set extinguish-radius 10
  set extinguish-rate 7

  set dropped-water 0
  set extinguishing-water 0
  ;; ---

  reset-ticks
end


;; Fire-fighting strategies
;; ---

;; Strategy is to not throw any water at all
to no-throw
end

;; Strategy is to throw water at random flaming tree
to uniform-throw

  ;; We set coordinates to -500 because we assume that no coordinate is lower than -500 and we want it to be overwritten if fire is present
  let x -500
  let y -500

  if any? turtles with [breed = fires]
  [
    ask one-of turtles with [breed = fires]
    [
      set x pxcor
      set y pycor
    ]
  ]


  ;; If x changed
  if (x > -500 )
  [
    drop-water x y
  ]

end

;; Strategy to find an 'epicenter' of fire and throw water there
to fire-throw
  let rx -1
  let ry -1
  let top -1

  let radius 3

  ask turtles with [breed = fires]
  [
    let current count turtles in-radius radius with [breed = fires]
    if (current > top)
    [
      set top current
      set rx pxcor
      set ry pycor
    ]
  ]

  drop-water rx ry
end

;; Strategy is to throw water on the the furthest fire at current wind direction
to wind-throw
  wind-throw-help turtles with [breed = fires]
end

to wind-throw-help [ turtles-given ]

  let coords []
  ask turtles-given
  [
    if ( wind-direction = "N" )
    [
      set coords find-max-at-given-direction turtles-given 0 1
    ]
    if ( wind-direction = "S" )
    [
      set coords find-max-at-given-direction turtles-given 0 -1
    ]
    if ( wind-direction = "E" )
    [
      set coords find-max-at-given-direction turtles-given 1 0
    ]
    if ( wind-direction = "W" )
    [
      set coords find-max-at-given-direction turtles-given -1 0
    ]
  ]

  let list-len length coords
  if ( list-len = 2 )
  [
    let x item 0 coords
    let y item 1 coords

    drop-water x y
  ]

end


to-report find-max-at-given-direction [ turtles-given dir-x dir-y ]

  ;; Initialize to an unreachable value
  let rx -300
  let ry -300

  ask turtles-given
  [
                                                                      ;; initial overwrite
    if (( pxcor * dir-x + pycor * dir-y > dir-x * rx + dir-y * ry ) or rx = -300)
    [
      set rx pxcor
      set ry pycor
    ]

  ]

  let res []
  set res lput rx res
  set res lput ry res
  report res
end

to-report wind-index [ t-patch ]
  if ( wind-direction = "N" )
  [
      report pycor / max-pycor
  ]

  if ( wind-direction = "S" )
  [
      report -1 * pycor / max-pycor
  ]

  if ( wind-direction = "W" )
  [
      report -1 * pxcor / max-pxcor
  ]

  if ( wind-direction = "E" )
  [
      report pxcor / max-pxcor
  ]
end

to density-wind

  let top-density -1
  let top-index -2
  let top-x -500
  let top-y 500

  let radius 3

  ask turtles with [breed = fires]
  [
    let current count turtles in-radius radius with [breed = fires]
    let density-standard current / 49
    let current-index wind-index self

    if ( density-standard + current-index > top-density + top-index )
    [
      set top-density density-standard
      set top-index current-index
      set top-x pxcor
      set top-y pycor
    ]
  ]

  drop-water top-x top-y

end
;; ---

;; Function to simulate helicopter water throw (drops water at given coordinates)
to drop-water [ px py ]

  extinguish-fire px py
  ask patches with [ ( (pxcor - px)^(2) + (pycor - py)^(2) <= extinguish-radius ) ]
    [
      set pcolor cyan
      set dropped-water dropped-water + 1
    ]
end

;; Sub-procedure for "drop-water" which kills "fires and embers" turtles
to extinguish-fire [ px py ]
  ask turtles with [breed = fires or breed = embers]
  [
    if ( (pxcor - px)^(2) + (pycor - py)^(2) <= extinguish-radius )
    [
      set extinguishing-water extinguishing-water + 1
      die
    ]
  ]
end

;; function to start fire at given coordinates (px,py) with radius
to init-fire [ px py radius ]
  ask patches with [ ( (pxcor - px)^(2) + (pycor - py)^(2) <= radius) and pcolor = green ]
    [ ignite ]
end

;; function to start fire with given radius in the middle
to center-init-fire [ radius ]
  init-fire 0 0 radius
end

;; function to start simulation
to go
  if not any? turtles  ;; either fires or embers
    [ stop ]
  spread-fire
  fade-embers

  ;; Start fire-fighting with given delay and with given rate
  if (ticks >= extinguish-starting-tick) and (ticks mod extinguish-rate = 0)
  [
    if (fighting-strategy = "Uniform")
    [
      uniform-throw
    ]
    if (fighting-strategy = "No fighting")
    [
      no-throw
    ]
    if (fighting-strategy = "Fire density")
    [
      fire-throw
    ]
    if (fighting-strategy = "Wind")
    [
      wind-throw
    ]
    if (fighting-strategy = "Density & wind")
    [
      wind-throw
    ]
  ]

  tick
end

to spread-fire-help [ t-patch direction opposite default1 default2 ]
    if t-patch != nobody
    [
      ask t-patch
      [
        if pcolor = green
        [
          (
            ifelse (wind-direction = direction) and ( (random-float 100) < wind-prob ) and ( ticks mod wind-spread = 0 )
            [
              ignite
            ]
            (wind-direction = opposite) and ( (random-float 100) < opposite-prob ) and ( ticks mod opposite-spread = 0 )
            [
              ignite
            ]
            (wind-direction != direction) and (wind-direction != opposite) and ( (random-float 100) < default-prob ) and ( ticks mod default-spread = 0 )
            [
              ignite
            ]
          )
        ]
      ]
    ]

end

;; function to spred fire (all conditions are taken into consideration)
to spread-fire
  ask fires
  [
    let north patch-at 0 1
    let south patch-at 0 -1
    let east patch-at 1 0
    let west patch-at -1 0

    spread-fire-help north "N" "S" "W" "E"
    spread-fire-help south "S" "N" "W" "E"
    spread-fire-help east "E" "W" "S" "N"
    spread-fire-help west "W" "E" "S" "N"

    if ( ticks mod spread-lcm = 0 )
    [
      set breed embers
    ]

  ]
end

;; creates the fire turtles
to ignite  ;; patch procedure
  sprout-fires 1
    [ set color red ]
  set pcolor black
  set burned-trees burned-trees + 1
end

;; achieve fading color effect for the fire as it burns
to fade-embers

  print spread-lcm
  if ( ticks mod spread-lcm = 0 )
  [
    ask embers
    [
      set color color - 1      ;; make red darker
      if color < red - 3.5     ;; are we almost at black?
        [ set pcolor color
          die
        ]
    ]
  ]


end


; Template code from:
; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
248
28
1058
579
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-200
200
-135
135
1
1
1
ticks
30.0

MONITOR
46
519
167
564
percent burned
(burned-trees / initial-trees)\n* 100
1
1
11

SLIDER
27
40
212
73
density
density
0.0
99.0
82.0
1.0
1
%
HORIZONTAL

BUTTON
128
81
197
117
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
48
81
118
117
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
133
283
225
328
wind-direction
wind-direction
"S" "N" "W" "E" "None"
1

SLIDER
31
138
203
171
extinguish-starting-tick
extinguish-starting-tick
0
100
26.0
1
1
NIL
HORIZONTAL

MONITOR
49
410
171
455
total water spent
dropped-water
17
1
11

PLOT
1095
170
1466
397
Growth of burned trees count
ticks
burned-trees / initial-trees
0.0
500.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot burned-trees / initial-trees"

CHOOSER
5
284
114
329
fighting-strategy
fighting-strategy
"Uniform" "No fighting" "Fire density" "Wind" "Density & wind"
3

SLIDER
32
188
204
221
wind-velocity
wind-velocity
0
100
68.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This project simulates the spread of a fire through a forest.  It shows that the fire's chance of reaching the right edge of the forest depends critically on the density of trees. This is an example of a common feature of complex systems, the presence of a non-linear threshold or critical parameter.

## HOW IT WORKS

The fire starts on the left edge of the forest, and spreads to neighboring trees. The fire spreads in four directions: north, east, south, and west.

The model assumes there is no wind.  So, the fire must have trees along its path in order to advance.  That is, the fire cannot skip over an unwooded area (patch), so such a patch blocks the fire's motion in that direction.

## HOW TO USE IT

Click the SETUP button to set up the trees (green) and fire (red on the left-hand side).

Click the GO button to start the simulation.

The DENSITY slider controls the density of trees in the forest. (Note: Changes in the DENSITY slider do not take effect until the next SETUP.)

## THINGS TO NOTICE

When you run the model, how much of the forest burns. If you run it again with the same settings, do the same trees burn? How similar is the burn from run to run?

Each turtle that represents a piece of the fire is born and then dies without ever moving. If the fire is made of turtles but no turtles are moving, what does it mean to say that the fire moves? This is an example of different levels in a system: at the level of the individual turtles, there is no motion, but at the level of the turtles collectively over time, the fire moves.

## THINGS TO TRY

Set the density of trees to 55%. At this setting, there is virtually no chance that the fire will reach the right edge of the forest. Set the density of trees to 70%. At this setting, it is almost certain that the fire will reach the right edge. There is a sharp transition around 59% density. At 59% density, the fire has a 50/50 chance of reaching the right edge.

Try setting up and running a BehaviorSpace experiment (see Tools menu) to analyze the percent burned at different tree density levels. Plot the burn-percentage against the density. What kind of curve do you get?

Try changing the size of the lattice (`max-pxcor` and `max-pycor` in the Model Settings). Does it change the burn behavior of the fire?

## EXTENDING THE MODEL

What if the fire could spread in eight directions (including diagonals)? To do that, use `neighbors` instead of `neighbors4`. How would that change the fire's chances of reaching the right edge? In this model, what "critical density" of trees is needed for the fire to propagate?

Add wind to the model so that the fire can "jump" greater distances in certain directions.

Add the ability to plant trees where you want them. What configurations of trees allow the fire to cross the forest? Which don't? Why is over 59% density likely to result in a tree configuration that works? Why does the likelihood of such a configuration increase so rapidly at the 59% density?

The physicist Per Bak asked why we frequently see systems undergoing critical changes. He answers this by proposing the concept of [self-organzing criticality] (https://en.wikipedia.org/wiki/Self-organized_criticality) (SOC). Can you create a version of the fire model that exhibits SOC?

## NETLOGO FEATURES

Unburned trees are represented by green patches; burning trees are represented by turtles.  Two breeds of turtles are used, "fires" and "embers".  When a tree catches fire, a new fire turtle is created; a fire turns into an ember on the next turn.  Notice how the program gradually darkens the color of embers to achieve the visual effect of burning out.

The `neighbors4` primitive is used to spread the fire.

You could also write the model without turtles by just having the patches spread the fire, and doing it that way makes the code a little simpler.   Written that way, the model would run much slower, since all of the patches would always be active.  By using turtles, it's much easier to restrict the model's activity to just the area around the leading edge of the fire.

See the "CA 1D Rule 30" and "CA 1D Rule 30 Turtle" for an example of a model written both with and without turtles.

## RELATED MODELS

* Percolation
* Rumor Mill

## CREDITS AND REFERENCES

https://en.wikipedia.org/wiki/Forest-fire_model

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Fire model.  http://ccl.northwestern.edu/netlogo/models/Fire.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 MIT -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
set density 60.0
setup
repeat 180 [ go ]
@#$#@#$#@
@#$#@#$#@
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