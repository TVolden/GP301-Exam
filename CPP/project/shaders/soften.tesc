#version 410 core

// define the number of CPs in the output patch
layout (vertices = 1) out;

uniform vec3 viewPosition;

// attributes of the input CPs
in VS_OUT {
   vec3 WorldPos;
   vec3 Normal;
   vec2 TexCoord;
   vec3 Tangent;
   vec3 Bitangent;
} cs_in[];

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

    vec3 Normal[3];
    vec2 TexCoord[3];
    vec3 Tangent[3];
    vec3 Bitangent[3];
};

out patch OutputPatch oPatch;

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

vec3 ProjectToPlane(vec3 Point, vec3 PlanePoint, vec3 PlaneNormal)
{
    vec3 v = Point - PlanePoint;
    float Len = dot(v, PlaneNormal);
    vec3 d = Len * PlaneNormal;
    return (Point - d);
}

void CalcPositions()
{
    // The original vertices stay the same
    oPatch.WorldPos_B030 = cs_in[0].WorldPos;
    oPatch.WorldPos_B003 = cs_in[1].WorldPos;
    oPatch.WorldPos_B300 = cs_in[2].WorldPos;

    // Edges are names according to the opposing vertex
    vec3 EdgeB300 = oPatch.WorldPos_B003 - oPatch.WorldPos_B030;
    vec3 EdgeB030 = oPatch.WorldPos_B300 - oPatch.WorldPos_B003;
    vec3 EdgeB003 = oPatch.WorldPos_B030 - oPatch.WorldPos_B300;

    // Generate two midpoints on each edge
    oPatch.WorldPos_B021 = oPatch.WorldPos_B030 + EdgeB300 / 3.0;
    oPatch.WorldPos_B012 = oPatch.WorldPos_B030 + EdgeB300 * 2.0 / 3.0;
    oPatch.WorldPos_B102 = oPatch.WorldPos_B003 + EdgeB030 / 3.0;
    oPatch.WorldPos_B201 = oPatch.WorldPos_B003 + EdgeB030 * 2.0 / 3.0;
    oPatch.WorldPos_B210 = oPatch.WorldPos_B300 + EdgeB003 / 3.0;
    oPatch.WorldPos_B120 = oPatch.WorldPos_B300 + EdgeB003 * 2.0 / 3.0;

    // Project each midpoint on the plane defined by the nearest vertex and its normal
    oPatch.WorldPos_B021 = ProjectToPlane(oPatch.WorldPos_B021, oPatch.WorldPos_B030, oPatch.Normal[0]);
    oPatch.WorldPos_B012 = ProjectToPlane(oPatch.WorldPos_B012, oPatch.WorldPos_B003, oPatch.Normal[1]);
    oPatch.WorldPos_B102 = ProjectToPlane(oPatch.WorldPos_B102, oPatch.WorldPos_B003, oPatch.Normal[1]);
    oPatch.WorldPos_B201 = ProjectToPlane(oPatch.WorldPos_B201, oPatch.WorldPos_B300, oPatch.Normal[2]);
    oPatch.WorldPos_B210 = ProjectToPlane(oPatch.WorldPos_B210, oPatch.WorldPos_B300, oPatch.Normal[2]);
    oPatch.WorldPos_B120 = ProjectToPlane(oPatch.WorldPos_B120, oPatch.WorldPos_B030, oPatch.Normal[0]);

    // Handle the center
    vec3 Center = (oPatch.WorldPos_B003 + oPatch.WorldPos_B030 + oPatch.WorldPos_B300) / 3.0;
    oPatch.WorldPos_B111 = (oPatch.WorldPos_B021 + oPatch.WorldPos_B012 + oPatch.WorldPos_B102 +
    oPatch.WorldPos_B201 + oPatch.WorldPos_B210 + oPatch.WorldPos_B120) / 6.0;
    oPatch.WorldPos_B111 += (oPatch.WorldPos_B111 - Center) / 2.0;
}

void main()
{
/*
    // Pass through the output from vertex shader
    //cs_out[gl_InvocationID].WorldPos = cs_in[gl_InvocationID].WorldPos;
    cs_out.Normal[gl_InvocationID] = cs_in[gl_InvocationID].Normal;
    cs_out.TexCoord[gl_InvocationID] = cs_in[gl_InvocationID].TexCoord;
    cs_out.Tangent[gl_InvocationID] = cs_in[gl_InvocationID].Tangent;
    cs_out.Bitangent[gl_InvocationID] = cs_in[gl_InvocationID].Bitangent;

    // Calculate the distance from the camera to the three control points
    float EyeToVertexDistance0 = distance(viewPosition, cs_in[0].WorldPos);
    float EyeToVertexDistance1 = distance(viewPosition, cs_in[1].WorldPos);
    float EyeToVertexDistance2 = distance(viewPosition, cs_in[2].WorldPos);
*/

    // Set the control points of the output patch
    for (int i = 0; i < 3; i++)
    {
        oPatch.Normal[i] = cs_in[i].Normal;
        oPatch.TexCoord[i] = cs_in[i].TexCoord;
        oPatch.Tangent[i] = cs_in[i].Tangent;
        oPatch.Bitangent[i] = cs_in[i].Bitangent;
    }

    CalcPositions();

    // Calculate the tessellation levels
    gl_TessLevelOuter[0] = 10;//GetTessLevel(EyeToVertexDistance1, EyeToVertexDistance2);
    gl_TessLevelOuter[1] = 10;//GetTessLevel(EyeToVertexDistance2, EyeToVertexDistance0);
    gl_TessLevelOuter[2] = 10;//GetTessLevel(EyeToVertexDistance0, EyeToVertexDistance1);
    gl_TessLevelInner[0] = gl_TessLevelOuter[2];
}