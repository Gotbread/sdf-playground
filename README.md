# sdf-playground

A small graphics engine for demos, small games, and playing around with SDFs in general.

## What are SDFs?

SDF stands for "Signed distance function". It is a mathematical function of space (either R² or R³) which for each point evaluates the scene and gives the closest distance to the scene geometry. If the distance to the scene is 0, this point lies on the surface. As its a "signed" distance function, we define the value to be positive outside an object and negative inside an object. By evaluating this signed distance function, we can find the objects.

This now gives us two tasks:

### Create an SDF for a complex scene

At first glance it does not seem trivial to find a mathematical function to describe a complex 3D scene. However, we can use a systematic approach:
-use basic primitives like boxes and spheres to build up the scene
-use translation, rotation, domain repetition, recursion, or operators to build more complex objects
-combine several objects (union, subtraction, intersection) into a more complex scene

### Find the objects in this scene

given an SDF, we can use several algoritms to turn the field into a scene one of the most popular ones is "sphere tracing"

![SDF explanation](Images/raymarch.png)

Here we sample the distance to the scene. We thusly know that we can march forward at least this distance value without hitting anything. After marching forward, we again sample the SDF and get the new distance. We repeat this either until we get very close to an object (value becomes close to zero) or the value gets very large, and we left the scene. This is a very basic algorithm, we can improve upon this one (its basicly a root finding algorithm), but largely how the engine works internally.

In order to apply colors and materials to the scene, we not only find the closest point to the scene, but also record properties for each object, which we can use in the engine.

## Effects

Light
Shadow
Transparency
Relfection
Refraction
HDR

![Reflections](Images/cube-sea.png)
The yellow cubes have a reflective material applied to them. Also note how we can have an infinite amount of them without much higher cost.

![Fractal 1](Images/fractal.png)
Fractals are done by recursively folding and scaling the scene. As such, they are not that expensive, and way cheaper then with a polygon based engine.
## Materials

Since materials can make use of the R³ position, its very easy to create "volumetric" materials which also fill the inside. A few examples:

![coordinate material](Images/coordinate%20material.png)
This material shows the coordinate lines. It can be adjusted how steep the slope for lines can get, and also if you want it in cartesian or spherical coordinates. Use the box_offset slider to move in and out a cutting object!

![distortion material](Images/distortion.png)
It is very tempting to modify the SDF directly, e.g. by adding a sine wave. This will mostly result in the distortion you wanted, but it breaks the promise of the SDF, that for each distance it reports, you can march this distance without encountering an object. This will lead to artifacts. One can combat this effect by reducing the step size artificially, at the cost of performance. It is possible however to add this distortion in a clever way without breaking the SDF or causing too much of a performance loss. This can be used to implement an arbitraty mathematical height offset. In this example image it is used to create a brick wall. Since it actually deforms the geometry, the surface will also be accuratly represented in e.g. shadows.

![Textures](Images/tiling.png)
The materials applied can have arbitrary complexity. Here we see 3 examples, from left to right:

-a voronoi glass window. Here the pane is tiled but each "cell" is irregular, giving it an unique look. For now the color is random, but you can assign each cell an unique color for nice effects. Position within the cell is also provided, here to create the darker border between the cells

-a truchet tiling. Here we chain the following methods together:
* First we split the area into tiles, each with an unique ID. We retain full control over the tile size or position
* For each cell, we define the basic pattern, here the 2 arcs. We also determine if they should be flipped or not (a slider is used to set the probability)
* For each position on the arc, we calculate local UV texture coordinates. These can also be animated
* We apply a texture to it based on these UV coordinates. It can be any texture. Here we use a simple stripe texture, resulting in this look

-a metal braided structure. We use a similar trick as above with tiling the area into smaller tiles. Here we shrink each tile a bit to see the (virtual) tile beneath it, and we also rotate it as to get this over-under-over-under braided look. Additionally we rotate and stretch it a bit so give this final look. The user has full control over the repetitions and the stretching. Behind the pane is the same material applied to a cylinder

## Other Scenes

![Basic sphere](Images/sphere.png)
This is the basic scene you see when starting the engine. It showcases some simple light and shadows, as well as a floor material. You can use this as starting point. Also noteworthy is that the sphere and the floor uses an analytic function to accelerate the ray intersection. Instead of marching 10-30 steps along they both find their intersection with only one step and are thus very fast to render.

![Fractal 2](Images/sierpinski.png)
Another fractal done by recursive strategy. Works correctly with lights and shadows.

## Getting started

If you want to play around, check out the different scenes and try to modify one a bit to see the effects. In order to create your own scene, use the `map` function to:
-define your geometry. Create your own or check the `sdf_primitives.hlsl` for existing ones. Add the object with the `OBJECT` makro to the scene
-give it a material. Use the `MATERIAL` makro for this. For the beginning, just set the `material_output.diffuse_color.rgb` field
-use the `map_light` function to define up to 8 simultaneous light sources, which can be point lights or directional lights
-use the `map_background` function to define a scene background
-if you want to skip the gradient evaluation, you can use the `map_normal` function to supply your own normal vectors. Can be left empty
