#version 410 core

layout (location = 0) in vec3 vertex;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 texCoord;
layout (location = 3) in vec3 tangent;
layout (location = 4) in vec3 bitangent;

out VS_OUT {
   vec3 WorldPos;
   vec3 Normal;
   vec2 TexCoord;
   vec3 Tangent;
   vec3 Bitangent;
} cs_in;

// transformations
uniform mat4 projection;   // camera projection matrix
uniform mat4 view;         // represents the world in the eye coord space
uniform mat4 model;        // represents model in the world coord space
uniform mat3 modelInvTra;  // inverse of the transpose of the model matrix, used to rotate vectors while preserving angles


void main() {
   // send texture coord to fragment shader
   cs_in.TexCoord = texCoord;

   // send tangent to tessellation evaluation shader
   cs_in.Tangent = tangent;
   cs_in.Bitangent = bitangent;

   // vertex normal in world space
   cs_in.Normal = normalize(modelInvTra * normal);

   // vertex position in world space
   cs_in.WorldPos = (model * vec4(vertex, 1.0)).xyz;
}