#pragma once
#include "dxApplication.h"
#include "renderPass.h"
#include "inputLayoutManager.h"
#include "camera.h"
#include "viewFrustrum.h"
#include "guiRenderer.h"
#include "modelLoader.h"

namespace mini::gk2 {
    class BokehDemoBase: public directx::dx_app {
    public:
        explicit BokehDemoBase(HINSTANCE hInst);

    protected:
        [[nodiscard]] int main_loop() override;

        void update(utils::clock const& clock) override;

        void render() override;

        std::optional<LRESULT> process_message(windows::message const& msg) override;

        size_t addModelFromFile(const std::string& path);

        size_t addModelFromString(const std::string& model, bool smoothNormals = true);

        size_t addPass(const std::wstring& vsShader, const std::wstring& psShader);

        size_t addPass(const std::wstring& vsShader, const std::wstring& gsShader, const std::wstring& psShader);

        size_t addPass(const std::wstring& vsShader, const std::wstring& psShader, const std::string& renderTarget,
                       bool clearRenderTarget = false);

        size_t addPass(const std::wstring& vsShader, const std::wstring& psShader,
                       const RenderTargetsEffect& renderTarget, bool clearRenderTarget = false);

        void addRasterizerState(size_t passId, const directx::rasterizer_info& desc);

        Model& model(const size_t modelId) { return *m_models[modelId]; }

        [[nodiscard]] const Model& model(const size_t modelId) const { return *m_models[modelId]; }

        RenderPass& pass(const size_t passId) { return m_passes[passId]; }

        [[nodiscard]] const RenderPass& pass(const size_t passId) const { return m_passes[passId]; }

        void addModelToPass(size_t passId, size_t modelId);

        void copyRenderTarget(size_t passId, const std::string& dstTexture);

        void copyDepthBuffer(size_t passId, const std::string& dstTexture);

        CBVariableManager m_variables;

    private:
        static constexpr float ROTATION_SPEED = 0.01F;
        static constexpr float ZOOM_SPEED = 0.02F;

        ModelLoader m_loader;
        std::vector<std::unique_ptr<Model>> m_models;
        std::vector<RenderPass> m_passes;
        InputLayoutManager m_layouts;
        directx::orbit_camera m_camera;
        ViewFrustrum m_frustrum;
        GUIRenderer m_gui;
    };
}
