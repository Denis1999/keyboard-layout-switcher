// Скрипт KWin для layout-fix. Загружается службой через D-Bus при входе в сеанс.
// 1) Сообщает службе активное окно: id, класс и заголовок (заголовок — и при
//    его смене, например при переключении вкладок). По ним служба узнаёт
//    терминалы и окна для паролей.
// 2) Забирает Pause и Shift+Pause, чтобы они не попадали в программы
//    (саму работу делает служба, она видит клавиши напрямую).
var current = null;

function send() {
    var w = current;
    callDBus("net.local.LayoutFix", "/", "net.local.LayoutFix", "Focus",
             w ? String(w.internalId) : "",
             w ? String(w.resourceClass) : "",
             w ? String(w.caption) : "");
}

function activated(w) {
    if (current) {
        try { current.captionChanged.disconnect(send); } catch (e) {}
    }
    current = w;
    if (w) {
        w.captionChanged.connect(send);
    }
    send();
}

workspace.windowActivated.connect(activated);
activated(workspace.activeWindow);

registerShortcut("layout-fix-word", "layout-fix: исправить последнее слово", "Pause", function () {});
registerShortcut("layout-fix-selection", "layout-fix: исправить выделенное", "Shift+Pause", function () {});
