﻿#include "exceptions.h"
#include "cbVariable.h"
#include "BokehDemo.h"

using namespace std;
using namespace mini;
using namespace DirectX;

int WINAPI wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE, _In_ LPWSTR, _In_ const int cmdShow) {
    auto exit_code = EXIT_FAILURE;
    constexpr UINT mb_flags = MB_OK;
    try {
        if (auto const hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED); FAILED(hr))
            throw utils::winapi_error{hr};
        if (!SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2))
            throw utils::winapi_error{};
        gk2::BokehDemo app(hInstance);

        exit_code = app.run(cmdShow);
    } catch (utils::exception& e) {
        MessageBoxW(nullptr, e.details().c_str(), e.message().c_str(), mb_flags);
        exit_code = e.exit_code();
    }
    catch (std::exception& e) {
        std::string s(e.what());
        MessageBoxW(nullptr, std::wstring(s.begin(), s.end()).c_str(), L"Błąd", mb_flags);
    }
    catch (const char* str) {
        std::string s(str);
        MessageBoxW(nullptr, std::wstring(s.begin(), s.end()).c_str(), L"Błąd", mb_flags);
    }
    catch (const wchar_t* str) {
        MessageBoxW(nullptr, str, L"Błąd", mb_flags);
    }
    catch (...) {
        MessageBoxW(nullptr, L"Nieznany Błąd", L"Błąd", mb_flags);
    }
    return exit_code;
}
