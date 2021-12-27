#version 410 core

layout(triangles, equal_spacing, ccw) in;

struct OutputPatch {
    vec3 WorldPos_B030;
    vec3 WorldPos_B021;
    vec3 WorldPos_B012;
    vec3 WorldPos_B003;
    vec3 WorldPos_B102;
    vec3 WorldPos_B201;
    vec3 WorldPos_B300;
    vec3 WorldPos_B210;
    vec3 WorldPos_B120;
    vec3 WorldPos_B111;

    vec3 Normal_200;
    vec3 Normal_020;
    vec3 Normal_002;
    vec3 Normal_011;
    vec3 Normal_101;
    vec3 Normal_110;

    vec3 Normal[3];
    vec2 TexCoord[3];
    vec3 Tangent[3];
    vec3 Bitangent[3];
};

in patch OutputPatch oPatch;

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

// Displacement variables
uniform sampler2D texture_ambient1;
uniform float displacementFactor;

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
    es_out.TexCoord = interpolate2D(oPatch.TexCoord[0], oPatch.TexCoord[1], oPatch.TexCoord[2]);

    // Interpolate the tangent
    vec3 tangen = interpolate3D(oPatch.Tangent[0], oPatch.Tangent[1], oPatch.Tangent[2]);

    // Normal in world space
    vec3 N = interpolate3D(oPatch.Normal[0], oPatch.Normal[1], oPatch.Normal[2]);

    //vec3 position = interpolate3D(cs_out[0].WorldPos, cs_out[1].WorldPos, cs_out[2].WorldPos);

    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    float w = gl_TessCoord.z;

    float uPow3 = pow(u, 3);
    float vPow3 = pow(v, 3);
    float wPow3 = pow(w, 3);
    float uPow2 = pow(u, 2);
    float vPow2 = pow(v, 2);
    float wPow2 = pow(w, 2);

    vec3 position = 
        oPatch.WorldPos_B300 * wPow3 +
        oPatch.WorldPos_B030 * uPow3 +
        oPatch.WorldPos_B003 * vPow3 +
        oPatch.WorldPos_B210 * 3.0 * wPow2 * u +
        oPatch.WorldPos_B120 * 3.0 * w * uPow2 +
        oPatch.WorldPos_B201 * 3.0 * wPow2 * v +
        oPatch.WorldPos_B021 * 3.0 * uPow2 * v +
        oPatch.WorldPos_B102 * 3.0 * w * vPow2 +
        oPatch.WorldPos_B012 * 3.0 * u * vPow2 +
        oPatch.WorldPos_B111 * 6.0 * w * u * v;
   /* 
    vec3 N = 
        oPatch.Normal_200 * wPow2 +
        oPatch.Normal_020 * uPow2 +
        oPatch.Normal_002 * vPow2 +
        oPatch.Normal_110 * w * u +
        oPatch.Normal_011 * u * v +
        oPatch.Normal_101 * w * v;
        */

    vec3 T = normalize(modelInvTra * tangen);
    T = normalize(T - dot(T, N) * N);
    vec3 B = -cross(N, T);
    mat3 TBN =  transpose(mat3(T, B, N)); // we transpose because we want T, B and N to be the rows of the matrix, not the columns
    
    // inverse of TBN, to map from tangent space to world space (needed for reflections)
    es_out.InverseTBN = transpose(TBN);
    
    // Displace the vertex along the normal
    float Displacement = texture(texture_ambient1, es_out.TexCoord.xy).x;
    position += N * Displacement * displacementFactor;

    // light direction, view position, vertex position, and normal in tangent space
    es_out.LightDir_tangent = TBN * lightDirection;
    es_out.CamPos_tangent = TBN * viewPosition;
    es_out.Pos_tangent  = TBN * position;
    es_out.Norm_tangent = TBN * N;

   // final vertex transform (for opengl rendering)
   gl_Position = projection * view * vec4(position, 1.0);
}
