cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME cutefish-texteditor)
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 COMPONENTS Core Quick REQUIRED)
find_package(KF6SyntaxHighlighting REQUIRED)

set(PROJECT_SOURCES
        src/main.cpp
        src/documenthandler.cpp
        src/highlightmodel.cpp
        src/texteditor.cpp
        qml.qrc
)

add_executable(${PROJECT_NAME}
  ${PROJECT_SOURCES}
)

target_link_libraries(cutefish-texteditor
  PRIVATE
  Qt6::Core
  Qt6::Quick
  KF6::SyntaxHighlighting
  )

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION /usr/bin)
