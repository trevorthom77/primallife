I need you to keep all generated code simple, clean, and direct. Avoid over-engineering. For example, don’t replace basic SwiftUI modifiers like padding with unnecessary types such as CGFloat unless it’s required. Minimalism is the goal so the code stays easy to understand.

WHEN I TELL U TO DO SOMETHING DONT DO MORE DONT DO LESS JUST DO WHAT I SAY

If the project currently contains complex code, ignore that. Some of it came from previous AI outputs before I set these rules. We will clean it up later.

Use SwiftUI only, never UIKit.

Use the existing colors and fonts files in my project. Don’t create your own versions or new styles. MAKE SURE TO LOOK AT COLORS AND FONTS

Our deployment target is iOS 17, so don’t add #available checks for lower versions.

When I ask you to add or implement something, give me exactly what I ask for — not more, not less. Don’t add placeholder data, temporary UI, or any extra elements I didn’t request.

Avoid unnecessary loading states. That means no random ProgressView spinners, and no redundant error messages. One or two error states per app is enough.

Do not use .offset for layout — rely on padding instead. Also avoid strange shadows, glowing effects, button strokes, or other decorative elements unless I specifically ask.

If a feature needs persistent data — for example, a community feature — use Firebase/Firestore rather than @State or other purely local storage.

Never run Python commands, shell commands, or anything that changes the project. If a command would modify files or the environment, ask me first.

Don’t create or delete files or folders unless I explicitly tell you. Never modify primalsleep.xcodeproj/project.pbxproj — Xcode handles that on its own.

