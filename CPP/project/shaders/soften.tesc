#version 410 core

// define the number of CPs in the output patch
layout (vertices = 3) out;

uniform vec3 viewPosition;

// attributes of the input CPs
struct VS_OUT {
   vec3 WorldPos;
   vec3 Normal;
   vec2 TexCoord;
   vec3 Tangent;
   vec3 Bitangent;
};

in VS_OUT cs_in[];
out VS_OUT cs_out[];

float GetTessLevel(float Distance0, float Distance1)
{
    float AvgDistance = (Distance0 + Distance1) / 2.0;

    if (AvgDistance <= 2.0) {
        return 10.0;
    }
    else if (AvgDistance <= 5.0) {
        return 7.0;
    }
    else {
        return 3.0;
    }
}

void main()
{
    // Pass through the output from vertex shader
    cs_out[gl_InvocationID] = cs_in[gl_InvocationID];

    // Calculate the distance from the camera to the three control points
    float EyeToVertexDistance0 = distance(viewPosition, cs_in[0].WorldPos);
    float EyeToVertexDistance1 = distance(viewPosition, cs_in[1].WorldPos);
    float EyeToVertexDistance2 = distance(viewPosition, cs_in[2].WorldPos);

    // Calculate the tessellation levels
    gl_TessLevelOuter[0] = GetTessLevel(EyeToVertexDistance1, EyeToVertexDistance2);
    gl_TessLevelOuter[1] = GetTessLevel(EyeToVertexDistance2, EyeToVertexDistance0);
    gl_TessLevelOuter[2] = GetTessLevel(EyeToVertexDistance0, EyeToVertexDistance1);
    gl_TessLevelInner[0] = gl_TessLevelOuter[2];
}