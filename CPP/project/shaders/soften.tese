#version 410 core

layout(triangles, equal_spacing, ccw) in;

//uniform sampler2D gDisplacementMap;
//uniform float gDispFactor;

in CS_OUT {
   vec3 WorldPos;
   vec3 Normal;
   vec2 TexCoord;
   vec3 Tangent;
   vec3 Bitangent;
} cs_out[];

out ES_OUT {
   vec3 CamPos_tangent;
   vec3 Pos_tangent;
   vec3 LightDir_tangent;
   vec3 Norm_tangent;
   vec2 TexCoord;
   mat3 InverseTBN;
} es_out;

// transformations
uniform mat4 projection;   // camera projection matrix
uniform mat4 view;         // represents the world in the eye coord space
uniform mat4 model;        // represents model in the world coord space
uniform mat3 modelInvTra;  // inverse of the transpose of the model matrix, used to rotate vectors while preserving angles

// light uniform variables
uniform vec3 lightDirection;
uniform vec3 viewPosition;

vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2)
{
    return vec2(gl_TessCoord.x) * v0 + vec2(gl_TessCoord.y) * v1 + vec2(gl_TessCoord.z) * v2;
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2)
{
    return vec3(gl_TessCoord.x) * v0 + vec3(gl_TessCoord.y) * v1 + vec3(gl_TessCoord.z) * v2;
}

void main()
{
    // Interpolate the attributes of the output vertex using the barycentric coordinates
    es_out.TexCoord = interpolate2D(cs_out[0].TexCoord, cs_out[1].TexCoord, cs_out[2].TexCoord);

    // Normal in world space
    vec3 N = interpolate3D(cs_out[0].Normal, cs_out[1].Normal, cs_out[2].Normal);
    N = normalize(N);

    // Interpolate the tangent
    vec3 tangen = interpolate3D(cs_out[0].Tangent, cs_out[1].Tangent, cs_out[2].Tangent);

    vec3 T = normalize(modelInvTra * tangen);
    T = normalize(T - dot(T, N) * N);
    vec3 B = -cross(N, T);
    mat3 TBN =  transpose(mat3(T, B, N)); // we transpose because we want T, B and N to be the rows of the matrix, not the columns
    
    // inverse of TBN, to map from tangent space to world space (needed for reflections)
    es_out.InverseTBN = transpose(TBN);

    vec3 position = interpolate3D(cs_out[0].WorldPos, cs_out[1].WorldPos, cs_out[2].WorldPos);
    
    // Displace the vertex along the normal
//    float Displacement = texture(gDisplacementMap, es_out.TexCoord.xy).x;
//    position += N * Displacement * gDispFactor;

    // light direction, view position, vertex position, and normal in tangent space
    es_out.LightDir_tangent = TBN * lightDirection;
    es_out.CamPos_tangent = TBN * viewPosition;
    es_out.Pos_tangent  = TBN * position; // NEW, there was a mistake in the original code, we use the vertex position so it gets interpolated during rasterization
    es_out.Norm_tangent = TBN * N;

   // final vertex transform (for opengl rendering)
   gl_Position = projection * view * vec4(position, 1.0);
}
