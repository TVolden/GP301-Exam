# Graphics Programming exam hand-in

> IT University of Copenhagen Improving models using tessellation Graphics Programming (Fall 2021) - KGGRPRG1KU  
> by Thomas Volden - 03/01/2022

## Introduction

Tessellation is a mathematical terminology which refers to the process of subdividing a surface into polygons. This is a frequent method in 3D graphics, where 3D models are typically subdivided into triangles, the simplest polygon, a process known as triangularization \[1\]. Historically, this was done via 3D modeling software, and the produced models were utilized in applications. As graphics hardware improved, additional capabilities were added, one of which was the ability to change the complexity of a mesh in real time. This may be used to scale details, displace vertices, smooth silhouettes or vice versa. The benefit of delegating this process to the graphics hardware, is that these operations can be used to performance-optimize applications such as games. OpenGL 4 includes the ability to implement tessellation shaders, in a way which imposes only a little extra work on vertex and fragment shaders. To learn more about OpenGL and tessellation shaders, the following research question was formulated. *How can tessellation be used to improve simple models, without modifying the original model?*

To investigate this a model was chosen from the classical 3D shooter game called Quake \[2\]. This game was chosen because it was published before 3D graphics hardware was common in private computers, which means it features very simple models.  
Two techniques were chosen to improve the model: Point normal triangles \[3\] and displacement mapping \[4\]. The point normal triangles can be used to curve a model making it more smooth, while displacement mapping can make models more detailed. When combined, they should be beneficial for optimizing a simple model and make it look more interesting.  
Concepts for the techniques will be introduced in the following sections and elaborated on later under the implementation details.

### Tessellation

![](images\image14.png)  
Figure 1: The render pipeline with focus on tessellation.

In OpenGL the procedure of tessellation is split into 3 stages, which are introduced in the render pipeline between the vertex shader and the fragment shader, see figure 1.
The output from the vertex shader is gathered in patches and parsed to the tessellation control shader (TCS). The TCS calculates the level of detail for the tessellation, which controls the number of generated triangles for a patch. Contrary to its name, the primitive generator does not generate primitives, instead it subdivides the patch into a domain \[8\]. In our example the domain is a triangle defined with barycentric coordinates u, v and w. The output of the TCS is parsed to the tessellation evaluation shader (TES), which then determines the final position of a vertex. The responsibility of the TES is similar to that of the vertex shader. The TES on the other hand, has barycentric coordinates available for every vertex, which can be used for position interpolation operations. For example Bézier patches, which will be introduced along with point normal triangles in the next section, use barycentric coordinates as input.

### Point normal triangles

Vlachos, Peters, Boyd and Mitchell introduced curved point normal triangles “as an inexpensive means of improving visual quality by smoothing out silhouette edges and providing more sample points for vertex shading operations.“ \[3, p. 159\]. They define point normal (PN) triangles as one cubic Bézier patch arranged to form a control net, see figure 2\.

![](images\image13.png)  
Figure 2: Triangular Bézier patch consisting of ten coefficients: three vertex (red), six tangent (blue) and one center (green).

To calculate the final position of a vertex, a set of coefficients are scaled and summarized, shown in formula 1:

1) $$b(u, v, w) = \sum_{i + j + k = 3} B_{ijk} \frac{3!}{i!j!k!} u^iv^jw^k, u+v+w = 1$$

The coefficients (noted as B in the formula) can effectively be calculated once and applied repeatedly for every position provided the barycentric parameters. The ten coefficients, which is shown in figure 2, are grouped together as vertex ($B_{300}$, $B_{030}$, $B_{003}$), tangent ($B_{012}$, $B_{021}$, $B_{102}$, $B_{120}$, $B_{201}$, $B_{210}$) and center ($B_{111}$)-coefficients.
The tangent coefficients can be calculated by interpolating between vertex coefficients, as shown in formula 2:

2) $$B_{ijk} = i\frac{B_{300}}{3}+j\frac{B_{030}}{3}+k\frac{B_{003}}{3},i,j,k\in\{0,1,2\} \wedge i+j+k = 3 \wedge i \neq j \neq k$$

Notice that the variables i, j and k will have the values 0, 1 and 2 assigned in various ways, thereby eliminating one vertex coefficient entirely and interpolating between the remaining two.

![](images\image15.png)  
Figure 3: Tangent coefficients (blue) are projected onto the plane of the nearest vertex (red) normal (green).

Figure 3 shows how to curve the triangle by projecting a vector from the closest vertex to the tangent coefficient onto the plane of the vertex normal, this is also expressed in formula 3:

3) $$ B'_{ijk} = B_{ijk} - (B_{ijk} - B_u) \cdot N_u * N_u, u = \begin{cases} 300 & \text{if $i = 2$} \\ 030 & \text{if $j = 2$} \\ 003 & \text{if $k = 2$} \\ \end{cases} $$

This formula ensures that a tangent coefficient is projected onto the plane regardless of whether it was initially located above or below the plane. Because the dot product of the vector and the normalized vertex normal will be negative if the angle between them is greater than 90 degrees.  
The center coefficient is set as halfway between the interpolated vertex coefficients and the interpolated tangent coefficients. Once all coefficients are calculated, they can be applied to vertex positions provided the barycentric parameters u, v and w.

### Displacement mapping

![](images\image17.png)  
Figure 4: Handmade height map for the quake player model.

Displacement mapping is a texture based procedural geometric positioning process, which is useful combined with tessellation to imprint details on a surface. Displacement mapping, in contrast to other approaches such as normal, bump and parallax mapping, can adjust silhouette edges and benefit from self shadowing \[4\]. The technique samples a monochrome heightmap to determine the final placement of a vertex along the surface normal, figure 4 shows the heightmap used for this project.

## Implementation

The details of which the techniques were implemented in this project, will be elaborated on in this section. A course exercise was used as a template for the project, in order to investigate how tessellation can be extended upon an existing code base. The eleventh exercise was chosen, as it was a forward rendering using lights and shadows. The car model was removed and a player model from Quake was inserted. The model was obtained by downloading a shareware version of the game from the internet. The asset bundle that came with it was unpacked, and a Quake-specific mdl-file was extracted and loaded into Blender, an open source 3D modeling application \[5\]. Finally the model was exported as a Wavefront obj-file \[6\] with no vertex normals included. As part of the import procedure, the Assimp library \[7\] was directed to compute smooth normals.  
Etay Meiri has published two tutorials that were used to enhance the code base: Basic tessellation \[8\] and PN Triangles Tessellation \[9\]. 

### Tessellation

In order to utilize tessellation in OpenGL, the input type must be set to patches when you call the *glDrawElements* method, an example is shown in table 1\.

Table 1: Example of change to the patches type in the project file *mesh.h:81*.

```cpp
glDrawElements(GL\_TRIANGLES, indices.size(), GL\_UNSIGNED\_INT, 0);
```
---
```cpp
glDrawElements(**GL\_PATCHES**, indices.size(), GL\_UNSIGNED\_INT, 0);
```

The size of a patch can be defined by calling *glPatchParameteri* method with *GL\_PATCH\_VERTICES* and the number of vertices per patch. Because triangles were used in this project, just three vertices were sufficient.  
As with other shaders, the tessellation shader files with the extensions .*tesc* for tessellation control and .*tese* for tessellation evaluation are compiled and attached to a program. The *shader.h* file was modified to accept two optional arguments with file paths to the tessellation shaders.  
The TCS defines the output with the *layout* keyword. The output of the TCS is directly transferred to the TES. If no advanced operation is needed, the TCS could simply output the patch array which it receives. The level of detail for the tessellation, which is the main responsibility of the TCS, is defined using the *gl\_TessLevelOuter* array and the *gl\_TessLevelInner* array. In this project the three outer levels and one inner level are set to the *uniform* variable *tessellationLevel* which can be set in the UI.  
The TES’s responsibility is to set the final position of each new vertex. This can be done by interpolating between the original vertices of the patch using the *gl\_TessCoord* 3D vector to access the barycentric parameters of the domain. Where the x, y and z values of the vector maps to the u, v and w parameters. In this project we constructed a Bézier patch to help interpolate between vertices. This will be explained in the next section.

### PN Triangles

In order to smooth out the model a bézier patch had to be constructed and applied, as explained under the introduction. The ten coefficients were calculated in the TCS. The vertex coefficients were set to the original three input vertices after which the tangent coefficients were calculated using formula 2 and 3\. As an example of how to calculate a tangent coefficient, the calculation for B120 is shown in equation 4:

4) $$ B'_{120}=B_{120}-(B_{120}-B_{030}) \cdot N_{030} * N_{030} , B_{120} = \frac{B_{300}}{3}+2 \frac{B_{030}}{3} $$

The center coefficient was found by summarizing all tangent coefficients and dividing them by six and summarizing all vertex coefficients and dividing them by three. Then the second result was subtracted from the first result and divided by two. To pass the coefficients to the TES a *struct* was created with the ten coefficients along with additional values for the fragment shader. The output layout was limited to one vertex, and to indicate shared values for the whole patch, a special keyword *patch* was added to the *out* variable in the TCS and the *in* variable in the TES. The TES calculated the global position by applying the barycentric parameters as shown in equation 5:

5)  $$ b(u,v,w) = \begin{array}{l} B_{300} w^3 + B_{030} u^3 + B_{003} v^3 + \\ B_{210} 3w^2u + B_{120} 3wu^2 + B_{201} 3w^2v + \\ B_{021} 3u^2v + B_{102}3wv^2 + B_{012} 3uv^2 + B_{111} 6wuv \end{array} $$

Other operations were moved from the vertex shader to the TES. The normal and tangent was interpolated between the 3 original vertex values and used to construct a tangent space matrix. Originally the vertex shader had set the *gl\_Position*, but this was also moved to the TES, to keep it simple. This meant that the vertex shader was reduced to pass on information and transform a vertex positions to global space.

### Displacement mapping

After determining the global position and surface normal in the TES, displacement was applied. An image editor was used to manually create a monochrome heightmap for the model. In order to attract the height map to the model, the wavefront mtl file \[6\] was appended with the line “disp heightmap.png”. The model importer was instructed to include displacement mapping as a uniform value for the shaders. In the shader, the sampled displacement map value was doubled and one was subtracted to set the range from minus one to one instead of zero to one. This made 50% grey color represent zero, while darker colors were negative and lighter colors were positive. The heightmap value was multiplied with a displacement factor to allow user control in the UI. The result will be examined in the next and final section.

## Result

![](images\image18.png)  
Figure 5: The original Quake player character (left), with applied PN triangle (middle) and displacement (right).

The character was imported and rendered using the tessellation shader program. The program has PN triangles and displacement mapping enabled by default, but they can be disabled or modified in the user interface, which can be accessed by pressing the spacebar. The result of applying both PN triangles and displacement mapping can be seen up close in figure 5\. The model looks smoother and facial features like the nose are clearly improved. Sharp objects like the axe become rounded, which may be undesirable. The model texture is still stretched. *Overall the model was improved and looks more interesting.*  
The biggest problem with the approach was that the displacement mapping produced “cracks” between patches (see the back of the head of the right picture). This is caused by unaligned vertex positions along the edge of the patches. The effect was reduced by adjusting the height map locally. A blur filter could be applied to the displacement sampling, like shadow mapping does, but this would constrain sharp edges like beneath the node.   
With some adjustments, these techniques could effectively improve simple models from old games, which could be used to remaster old games.

## Resources

1. Tessellation, Wikipedia: [https://en.wikipedia.org/wiki/Tessellation\_(computer\_graphics)](https://en.wikipedia.org/wiki/Tessellation_\(computer_graphics\))  
2. Quake (1996, Juli), id Software, Activision in, url: [https://www.uvlist.net/game-19657-Quake](https://www.uvlist.net/game-19657-Quake)  
3. Vlachos, A., Peters, J., Boyd, C., & Mitchell, J. L. (2001, March). Curved PN triangles. In *Proceedings of the 2001 symposium on Interactive 3D graphics* (pp. 159-166).  
4. Displacement mapping, Wikipedia: [https://en.wikipedia.org/wiki/Displacement\_mapping](https://en.wikipedia.org/wiki/Displacement_mapping)  
5. Blender, [https://www.blender.org/](https://www.blender.org/)  
6. Wavefront .obj file, Wikipedia: [https://en.wikipedia.org/wiki/Wavefront\_.obj\_file](https://en.wikipedia.org/wiki/Wavefront_.obj_file)  
7. The Open-Asset-Importer-Lib, [https://www.assimp.org/](https://www.assimp.org/)  
8. Meiri, E., Tutorial 30: Basic Tessellation, [https://ogldev.org/www/tutorial30/tutorial30.html](https://ogldev.org/www/tutorial30/tutorial30.html)  
9. Meiri, E., Tutorial 31: PN Triangles Tessellation, [https://ogldev.org/www/tutorial31/tutorial31.html](https://ogldev.org/www/tutorial31/tutorial31.html)