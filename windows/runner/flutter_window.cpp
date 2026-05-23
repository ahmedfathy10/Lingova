#include "flutter_window.h"

#include <shlobj.h>
#include <windows.h>

#include <filesystem>
#include <fstream>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

namespace {

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  int size = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return std::wstring(value.begin(), value.end());
  }

  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, wide.data(), size);
  return wide;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  int size = WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, nullptr, 0,
                                 nullptr, nullptr);
  if (size <= 0) {
    return std::string();
  }

  std::string utf8(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, utf8.data(), size,
                      nullptr, nullptr);
  return utf8;
}

std::wstring SanitizeFileName(std::wstring file_name) {
  const std::wstring invalid = L"\\/:*?\"<>|";
  for (wchar_t& character : file_name) {
    if (invalid.find(character) != std::wstring::npos ||
        character < static_cast<wchar_t>(32)) {
      character = L'_';
    }
  }

  while (!file_name.empty() &&
         (file_name.back() == L'.' || file_name.back() == L' ')) {
    file_name.pop_back();
  }

  if (file_name.empty()) {
    return L"certificate.pdf";
  }
  return file_name;
}

std::filesystem::path GetDownloadsFolder() {
  PWSTR downloads_path = nullptr;
  HRESULT result = SHGetKnownFolderPath(FOLDERID_Downloads, 0, nullptr,
                                        &downloads_path);
  if (SUCCEEDED(result) && downloads_path != nullptr) {
    std::filesystem::path path(downloads_path);
    CoTaskMemFree(downloads_path);
    return path;
  }

  wchar_t user_profile[MAX_PATH];
  DWORD size = GetEnvironmentVariableW(L"USERPROFILE", user_profile, MAX_PATH);
  if (size > 0 && size < MAX_PATH) {
    return std::filesystem::path(user_profile) / L"Downloads";
  }

  return std::filesystem::current_path();
}

std::string SavePdfToDownloads(const std::string& file_name,
                               const std::vector<uint8_t>& bytes) {
  std::filesystem::path folder = GetDownloadsFolder() / L"Lingova";
  std::error_code directory_error;
  std::filesystem::create_directories(folder, directory_error);
  if (directory_error) {
    throw std::runtime_error("Could not create Downloads folder.");
  }

  std::filesystem::path file_path =
      folder / SanitizeFileName(Utf8ToWide(file_name));

  std::ofstream output(file_path, std::ios::binary);
  if (!output.is_open()) {
    throw std::runtime_error("Could not create PDF file.");
  }

  output.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
  if (!output.good()) {
    throw std::runtime_error("Could not write PDF file.");
  }

  return WideToUtf8(file_path.wstring());
}

void RegisterDownloadsChannel(flutter::FlutterEngine* engine,
                              std::unique_ptr<flutter::MethodChannel<
                                  flutter::EncodableValue>>& channel) {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "lingova/downloads",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "savePdf") {
          result->NotImplemented();
          return;
        }

        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "Expected arguments map.");
          return;
        }

        auto file_name_it =
            arguments->find(flutter::EncodableValue("fileName"));
        auto bytes_it = arguments->find(flutter::EncodableValue("bytes"));

        std::string file_name = "certificate.pdf";
        if (file_name_it != arguments->end()) {
          if (const auto* value =
                  std::get_if<std::string>(&file_name_it->second)) {
            file_name = *value;
          }
        }

        if (bytes_it == arguments->end()) {
          result->Error("missing_bytes", "No PDF bytes were provided.");
          return;
        }

        const auto* bytes = std::get_if<std::vector<uint8_t>>(&bytes_it->second);
        if (bytes == nullptr) {
          result->Error("invalid_bytes", "PDF bytes must be binary data.");
          return;
        }

        try {
          result->Success(flutter::EncodableValue(
              SavePdfToDownloads(file_name, *bytes)));
        } catch (const std::exception& error) {
          result->Error("save_failed", error.what());
        }
      });
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterDownloadsChannel(flutter_controller_->engine(),
                           downloads_channel_);
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
