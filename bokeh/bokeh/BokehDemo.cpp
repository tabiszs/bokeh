#include "BokehDemo.h"

using namespace mini;
using namespace gk2;
using namespace DirectX;
using namespace std;
using namespace directx;
using namespace utils;

auto operator/(const SIZE& s, const float f) -> SIZE {
    const auto x = static_cast<float>(s.cx);
    const auto y = static_cast<float>(s.cy);
    return {static_cast<LONG>(x / f), static_cast<LONG>(y / f)};
}

BokehDemo::BokehDemo(HINSTANCE hInst): BokehDemoBase(hInst) {
    // Shader Variables
    m_variables.AddSemanticVariable("modelMtx", VariableSemantic::MatM);
    m_variables.AddSemanticVariable("modelInvTMtx", VariableSemantic::MatMInvT);
    m_variables.AddSemanticVariable("viewProjMtx", VariableSemantic::MatVP);
    m_variables.AddSemanticVariable("camPos", VariableSemantic::Vec4CamPos);

    constexpr XMFLOAT4 lightPos[2] = {
        {-1.0F, 0.0F, -3.5F, 1.0F},
        {0.0F, 3.5F, 0.0F, 1.0F},
    };

    constexpr XMFLOAT3 lightColor[2] = {
        {12.0F, 9.0F, 10.0F},
        {1.0F, 0.0F, 30.0F},
    };
    m_variables.AddGuiVariable("lightPos", lightPos, -10, 10);
    m_variables.AddGuiColorsVariable("lightColor", lightColor);
    m_variables.AddGuiVariable("m", 50.f, 10.f, 200.f);

#define TEXTURE(kind) L"textures/dented-metal/" #kind ".png"
    m_variables.AddSampler(m_device, "samp");
    m_variables.AddTexture(m_device, "normTex", TEXTURE(normal));
    m_variables.AddTexture(m_device, "albedoTex", TEXTURE(albedo));
    m_variables.AddTexture(m_device, "roughnessTex", TEXTURE(roughness));
    m_variables.AddTexture(m_device, "metallnessTex", TEXTURE(metallic));

    m_variables.AddTexture(m_device, "irMap", L"textures/cubeMapIrradiance.dds");
    m_variables.AddTexture(m_device, "pfEnvMap", L"textures/cubeMapRadiance.dds");
    m_variables.AddTexture(m_device, "brdfTex", L"textures/brdf_lut.png");


    constexpr auto h0 = 1.5F;
    m_variables.AddGuiVariable("h0", h0, 0, 3);
    m_variables.AddGuiVariable("l", 15.f, 5, 25);
    m_variables.AddGuiVariable("r", 0.5f, 0.01f, 1);
    m_variables.AddGuiVariable("rsmall", 0.1f, 0.01f, 0.5f);

    m_variables.AddGuiVariable("thalf", 3.f, 1.f, 5.f);
    m_variables.AddGuiVariable("xmax", .5f, .1f, 1.f);
    m_variables.AddGuiVariable("vmax", 4.f, .5f, 10.f);
    m_variables.AddSemanticVariable("time", VariableSemantic::FloatT);

    m_variables.AddTexture(m_device, "envMap", L"textures/cubeMap.dds");
    m_variables.AddTexture(m_device, "perlin", L"textures/NoiseVolume.dds");

    m_variables.AddSemanticVariable("mvpMtx", VariableSemantic::MatMVP);
    m_variables.AddGuiVariable("waterLevel", -0.05F, -1, 1, 0.001F);

    m_variables.AddGuiVariable("lightPos", lightPos, -10, 10);
    m_variables.AddGuiVariable("lightColor", lightColor, 0, 100, 1);

    // variables // BOKEH
    constexpr auto angle = 0.0F;
    constexpr auto coc_factor = 1.0F;
    constexpr auto NUM_SAMPLES = 16.0F;
    m_variables.AddGuiVariable("NUM_SAMPLES", NUM_SAMPLES, 1, 32, 1);
    m_variables.AddGuiVariable("coc_factor", coc_factor, 0.8f, 1.2f);
    m_variables.AddGuiVariable("angle", angle, -XM_PI, XM_PI, 0.1f);

    auto screenSize = get_window().client_size();
    m_variables.AddRenderableTexture(m_device, "sceneTexture", screenSize);

    // Samplers // BOKEH
    sampler_info sDesc;
    sDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    sDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    sDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    m_variables.AddSampler(m_device, "blurSampler", sDesc);

    m_variables.AddSemanticVariable("nearZ", VariableSemantic::FloatNearPlane);
    m_variables.AddTexture(m_device, "screenColor",
                           tex2d_info(screenSize.cx, screenSize.cy,
                                      DXGI_FORMAT_R8G8B8A8_UNORM, 1));
    m_variables.AddTexture(m_device, "screenDepth",
        tex2d_info(screenSize.cx, screenSize.cy,
            DXGI_FORMAT_R24_UNORM_X8_TYPELESS, 1));

    // Models
    const auto teapot = addModelFromFile("models/Teapot.3ds");
    XMFLOAT4X4 teapotMtx{};
    XMStoreFloat4x4(
        &teapotMtx,
        XMMatrixScaling(1.0F / 60, 1.0F / 60, 1.0F / 60)
        * XMMatrixRotationX(-XM_PIDIV2)
        * XMMatrixTranslation(0, 0.5F - h0, 0)
    );
    model(teapot).applyTransform(teapotMtx);

    const auto skull = addModelFromFile("models/skull.obj");
    XMFLOAT4X4 skullMtx{};
    XMStoreFloat4x4(
        &skullMtx,
        XMMatrixScaling(0.2F, 0.2F, 0.2F)
        * XMMatrixRotationX(XM_PIDIV2)
        * XMMatrixTranslation(2, 1, 6)
    );
    model(skull).applyTransform(skullMtx);

    const auto capsule = addModelFromFile("models/capsule.obj");
    XMFLOAT4X4 capsuleMtx{};
    XMStoreFloat4x4(
        &capsuleMtx,
        XMMatrixScaling(0.1F, 0.1F, 0.1F)
        * XMMatrixRotationX(XM_PIDIV2)
        * XMMatrixTranslation(-1, 3, 5)
    );
    model(capsule).applyTransform(capsuleMtx);

    const auto plane = addModelFromFile("models/Plane.obj");
    XMFLOAT4X4 planeMtx{};
    XMStoreFloat4x4(&planeMtx, XMMatrixTranslation(0, -h0, 0));
    model(plane).applyTransform(planeMtx);

    const auto quad = addModelFromString(
        "pp 4\n1 0 1 0 1 0\n1 0 -1 0 1 0\n"
        "-1 0 -1 0 1 0\n-1 0 1 0 1 0\n"
    );
    const auto envModel = addModelFromString("hex 0 0 0 1.73205");
    XMFLOAT4X4 envMtx{};
    XMStoreFloat4x4(&envMtx, XMMatrixScaling(20, 20, 20));
    model(quad).applyTransform(envMtx);
    model(envModel).applyTransform(envMtx);


    //Render Passes
    // teapot
    const auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso", "sceneTexture");
    addModelToPass(passTeapot, teapot);

    // skull
    const auto passSkull = addPass(L"skullVS.cso", L"skullPS.cso", "sceneTexture");
    addModelToPass(passSkull, skull);

    // capsule
    const auto passCapsule = addPass(L"capsuleVS.cso", L"capsulePS.cso", "sceneTexture");
    addModelToPass(passCapsule, capsule);

    // spring
    const auto passSpring = addPass(L"springVS.cso", L"springPS.cso", "sceneTexture");
    addModelToPass(passSpring, plane);

    // water
    const auto passWater = addPass(L"waterVS.cso", L"waterPS.cso", "sceneTexture");
    addModelToPass(passWater, quad);
    rasterizer_info rs;
    rs.CullMode = D3D11_CULL_NONE;
    addRasterizerState(passWater, rs);

    // cube map
    const auto passEnv = addPass(L"envVS.cso", L"envPS.cso", "sceneTexture");
    addModelToPass(passEnv, envModel);
    addRasterizerState(passEnv, rasterizer_info(true));


    // blur filtering BOKEH
    // add textures as double render target
    directx::tex2d_info desc(screenSize.cx, screenSize.cy);
    desc.BindFlags |= D3D11_BIND_RENDER_TARGET;
    desc.MipLevels = 1;
    auto verticalBlurTexture = m_device.CreateTexture(desc);
    m_variables.AddTexture(m_device, "verticalBlurTexture", verticalBlurTexture);
    auto diagonalBlurTexture = m_device.CreateTexture(desc);
    m_variables.AddTexture(m_device, "diagonalBlurTexture", diagonalBlurTexture);

    SIZE s{ static_cast<LONG>(desc.Width), static_cast<LONG>(desc.Height) };
    auto doubleTextureTarget = RenderTargetsEffect(directx::viewport{ s }, m_device.CreateDepthStencilView(s.cx, s.cy));
    doubleTextureTarget.SetRenderTargets({ m_device.CreateRenderTargetView(verticalBlurTexture).get(), m_device.CreateRenderTargetView(diagonalBlurTexture).get() });

    auto passBlurBokeh1 = addPass(L"fullScreenQuadVS.cso", L"bokeh1PS.cso", doubleTextureTarget, true);
    addModelToPass(passBlurBokeh1, quad);
    auto passBlurBokeh2 = addPass(L"fullScreenQuadVS.cso", L"bokeh2PS.cso", window_target());
    addModelToPass(passBlurBokeh2, quad);
}
