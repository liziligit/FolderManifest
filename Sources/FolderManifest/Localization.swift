import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portugueseBrazil = "pt-BR"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .english: "English"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .portugueseBrazil: "Português (Brasil)"
        }
    }

    var localeIdentifier: String { rawValue }
}

@MainActor
final class LanguageSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "appLanguage"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Self.storageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .simplifiedChinese
    }
}

struct AppStrings: Sendable {
    let language: AppLanguage

    private func text(
        _ zhHans: String,
        _ zhHant: String,
        _ en: String,
        _ ja: String,
        _ ko: String,
        _ es: String,
        _ fr: String,
        _ de: String,
        _ ptBR: String
    ) -> String {
        switch language {
        case .simplifiedChinese: zhHans
        case .traditionalChinese: zhHant
        case .english: en
        case .japanese: ja
        case .korean: ko
        case .spanish: es
        case .french: fr
        case .german: de
        case .portugueseBrazil: ptBR
        }
    }

    private func formattedCount(_ count: Int) -> String {
        count.formatted(.number.locale(Locale(identifier: language.localeIdentifier)))
    }

    var settings: String { text("设置", "設定", "Settings", "設定", "설정", "Ajustes", "Réglages", "Einstellungen", "Ajustes") }
    var showMainWindow: String { text("显示主窗口", "顯示主視窗", "Show Main Window", "メインウインドウを表示", "메인 윈도우 보기", "Mostrar ventana principal", "Afficher la fenêtre principale", "Hauptfenster anzeigen", "Mostrar janela principal") }
    var languageLabel: String { text("界面语言", "介面語言", "Interface Language", "表示言語", "인터페이스 언어", "Idioma de la interfaz", "Langue de l’interface", "Oberflächensprache", "Idioma da interface") }
    var languageHint: String { text("选择后立即应用，并在下次启动时保留。", "選擇後立即套用，並在下次啟動時保留。", "Changes apply immediately and are kept for the next launch.", "選択内容はすぐに適用され、次回起動時にも保持されます。", "선택 즉시 적용되며 다음 실행 시에도 유지됩니다.", "Los cambios se aplican de inmediato y se conservan para el próximo inicio.", "Les changements s’appliquent immédiatement et sont conservés au prochain lancement.", "Änderungen werden sofort übernommen und für den nächsten Start gespeichert.", "As alterações são aplicadas imediatamente e mantidas na próxima abertura.") }

    var appSubtitle: String { text("文件夹目录清单生成器", "資料夾目錄清單產生器", "Folder manifest generator", "フォルダ一覧ジェネレーター", "폴더 목록 생성기", "Generador de manifiestos de carpetas", "Générateur de manifeste de dossiers", "Ordnerlisten-Generator", "Gerador de manifesto de pastas") }
    var selectFolder: String { text("选择文件夹", "選擇資料夾", "Choose Folder", "フォルダを選択", "폴더 선택", "Elegir carpeta", "Choisir un dossier", "Ordner auswählen", "Escolher pasta") }
    var changeFolder: String { text("更换文件夹", "更換資料夾", "Change Folder", "フォルダを変更", "폴더 변경", "Cambiar carpeta", "Changer de dossier", "Ordner wechseln", "Alterar pasta") }
    var releaseToScan: String { text("松开即可扫描", "放開即可掃描", "Release to scan", "ドロップしてスキャン", "놓아서 스캔", "Suelta para escanear", "Relâchez pour analyser", "Zum Scannen loslassen", "Solte para escanear") }
    var dropFolderHere: String { text("把文件夹拖到这里", "將資料夾拖到這裡", "Drag a folder here", "フォルダをここにドラッグ", "폴더를 여기에 드래그", "Arrastra una carpeta aquí", "Glissez un dossier ici", "Ordner hierher ziehen", "Arraste uma pasta para cá") }
    var emptyDescription: String { text("读取目录结构，生成清晰、可复制的文件清单", "讀取目錄結構，產生清晰、可複製的檔案清單", "Read a folder structure and create a clear, copyable manifest", "フォルダ構成を読み取り、見やすくコピー可能な一覧を作成します", "폴더 구조를 읽어 깔끔하고 복사 가능한 목록을 만듭니다", "Lee la estructura y crea un manifiesto claro y copiable", "Analyse la structure et crée un manifeste clair et copiable", "Liest die Ordnerstruktur und erstellt eine übersichtliche, kopierbare Liste", "Lê a estrutura e cria um manifesto claro e copiável") }
    var chooseFolderEllipsis: String { selectFolder + "…" }
    var fullyOffline: String { text("完全离线", "完全離線", "Fully Offline", "完全オフライン", "완전 오프라인", "Totalmente sin conexión", "Entièrement hors ligne", "Vollständig offline", "Totalmente offline") }
    var readOnlyScan: String { text("只读扫描", "唯讀掃描", "Read-only Scan", "読み取り専用", "읽기 전용 스캔", "Escaneo de solo lectura", "Analyse en lecture seule", "Schreibgeschützter Scan", "Varredura somente leitura") }
    var oneClickExport: String { text("一键导出", "一鍵匯出", "One-click Export", "ワンクリック書き出し", "원클릭 내보내기", "Exportación en un clic", "Export en un clic", "Ein-Klick-Export", "Exportação em um clique") }

    var scanScope: String { text("扫描范围", "掃描範圍", "Scan Scope", "スキャン範囲", "스캔 범위", "Alcance del escaneo", "Étendue de l’analyse", "Scanumfang", "Escopo da varredura") }
    var includeSubfolders: String { text("包含子文件夹", "包含子資料夾", "Include Subfolders", "サブフォルダを含める", "하위 폴더 포함", "Incluir subcarpetas", "Inclure les sous-dossiers", "Unterordner einbeziehen", "Incluir subpastas") }
    var includeHidden: String { text("包含隐藏文件", "包含隱藏檔案", "Include Hidden Files", "隠しファイルを含める", "숨김 파일 포함", "Incluir archivos ocultos", "Inclure les fichiers masqués", "Versteckte Dateien einbeziehen", "Incluir arquivos ocultos") }
    var foldersFirst: String { text("文件夹优先", "資料夾優先", "Folders First", "フォルダを先に表示", "폴더 우선", "Carpetas primero", "Dossiers en premier", "Ordner zuerst", "Pastas primeiro") }
    var sortBy: String { text("排序方式", "排序方式", "Sort By", "並べ替え", "정렬 기준", "Ordenar por", "Trier par", "Sortieren nach", "Ordenar por") }
    var recentlyOpened: String { text("最近打开", "最近開啟", "Recently Opened", "最近開いた項目", "최근에 연 폴더", "Abiertos recientemente", "Ouverts récemment", "Zuletzt geöffnet", "Abertos recentemente") }
    var noRecentFolders: String { text("暂无记录", "暫無記錄", "No recent folders", "履歴はありません", "최근 폴더 없음", "No hay carpetas recientes", "Aucun dossier récent", "Keine zuletzt geöffneten Ordner", "Nenhuma pasta recente") }
    var pinnedCountPrefix: String { text("已固定", "已固定", "Pinned ", "固定 ", "고정 ", "Fijadas ", "Épinglés ", "Angeheftet ", "Fixadas ") }
    var pinnedCountSuffix: String { text("个", "個", "", "件", "개", "", "", "", "") }
    var pinFolder: String { text("固定文件夹", "固定資料夾", "Pin Folder", "フォルダを固定", "폴더 고정", "Fijar carpeta", "Épingler le dossier", "Ordner anheften", "Fixar pasta") }
    var unpinFolder: String { text("取消固定", "取消固定", "Unpin Folder", "固定を解除", "폴더 고정 해제", "Desfijar carpeta", "Désépingler le dossier", "Ordner lösen", "Desafixar pasta") }
    var pinnedLimitReached: String { text("最多固定 25 个文件夹", "最多固定 25 個資料夾", "Up to 25 folders can be pinned", "固定できるフォルダは25件までです", "폴더는 최대 25개까지 고정할 수 있습니다", "Se pueden fijar hasta 25 carpetas", "Vous pouvez épingler jusqu’à 25 dossiers", "Es können bis zu 25 Ordner angeheftet werden", "É possível fixar até 25 pastas") }
    var movePinnedUp: String { text("上移固定文件夹", "上移固定資料夾", "Move Pinned Folder Up", "固定フォルダを上へ", "고정 폴더 위로 이동", "Subir carpeta fijada", "Monter le dossier épinglé", "Angehefteten Ordner nach oben", "Mover pasta fixada para cima") }
    var movePinnedDown: String { text("下移固定文件夹", "下移固定資料夾", "Move Pinned Folder Down", "固定フォルダを下へ", "고정 폴더 아래로 이동", "Bajar carpeta fijada", "Descendre le dossier épinglé", "Angehefteten Ordner nach unten", "Mover pasta fixada para baixo") }
    var displayInformation: String { text("显示信息", "顯示資訊", "Display Information", "表示情報", "표시 정보", "Información mostrada", "Informations affichées", "Angezeigte Informationen", "Informações exibidas") }
    var fileSize: String { text("文件大小", "檔案大小", "File Size", "ファイルサイズ", "파일 크기", "Tamaño del archivo", "Taille du fichier", "Dateigröße", "Tamanho do arquivo") }
    var modifiedDate: String { text("修改时间", "修改時間", "Modified Date", "更新日時", "수정 시간", "Fecha de modificación", "Date de modification", "Änderungsdatum", "Data de modificação") }
    var filesInFolder: String { text("文件夹内文件数", "資料夾內檔案數", "Files in Folder", "フォルダ内のファイル数", "폴더 내 파일 수", "Archivos en la carpeta", "Fichiers dans le dossier", "Dateien im Ordner", "Arquivos na pasta") }
    var rescan: String { text("重新扫描", "重新掃描", "Rescan", "再スキャン", "다시 스캔", "Volver a escanear", "Analyser à nouveau", "Erneut scannen", "Escanear novamente") }

    var files: String { text("文件", "檔案", "Files", "ファイル", "파일", "Archivos", "Fichiers", "Dateien", "Arquivos") }
    var folders: String { text("文件夹", "資料夾", "Folders", "フォルダ", "폴더", "Carpetas", "Dossiers", "Ordner", "Pastas") }
    var totalSize: String { text("总大小", "總大小", "Total Size", "合計サイズ", "전체 크기", "Tamaño total", "Taille totale", "Gesamtgröße", "Tamanho total") }
    var skipped: String { text("已跳过", "已略過", "Skipped", "スキップ", "건너뜀", "Omitidos", "Ignorés", "Übersprungen", "Ignorados") }
    var copy: String { text("复制", "複製", "Copy", "コピー", "복사", "Copiar", "Copier", "Kopieren", "Copiar") }
    var export: String { text("导出", "匯出", "Export", "書き出す", "내보내기", "Exportar", "Exporter", "Exportieren", "Exportar") }
    var searchPlaceholder: String { text("正则搜索，例如：\\.pdf$、报告.*2026 或 ^课程 · 双击文件名打开所在文件夹", "正規表示式搜尋，例如：\\.pdf$、報告.*2026 或 ^課程 · 按兩下檔名開啟所在資料夾", "Regex search, e.g. \\.pdf$, report.*2026 or ^course · Double-click a filename to open its folder", "正規表現検索：\\.pdf$、report.*2026、^course など · ファイル名をダブルクリックして保存場所を開く", "정규식 검색 예: \\.pdf$, report.*2026 또는 ^course · 파일 이름을 이중 클릭하여 포함된 폴더 열기", "Búsqueda regex, p. ej. \\.pdf$, informe.*2026 o ^curso · Haz doble clic en un archivo para abrir su carpeta", "Recherche regex, ex. \\.pdf$, rapport.*2026 ou ^cours · Double-cliquez sur un fichier pour ouvrir son dossier", "Regex-Suche, z. B. \\.pdf$, Bericht.*2026 oder ^Kurs · Dateinamen doppelklicken, um den Ordner zu öffnen", "Busca regex, ex.: \\.pdf$, relatório.*2026 ou ^curso · Clique duas vezes no arquivo para abrir a pasta") }
    var clearSearch: String { text("清除搜索", "清除搜尋", "Clear Search", "検索をクリア", "검색 지우기", "Borrar búsqueda", "Effacer la recherche", "Suche löschen", "Limpar busca") }
    var searchHint: String { text("忽略大小写 · 匹配完整路径", "忽略大小寫 · 比對完整路徑", "Case-insensitive · Matches full path", "大文字小文字を区別しない · フルパスを検索", "대소문자 무시 · 전체 경로 일치", "Sin distinguir mayúsculas · Coincide con la ruta completa", "Insensible à la casse · Correspond au chemin complet", "Groß-/Kleinschreibung ignoriert · Vollständiger Pfad", "Ignora maiúsculas · Corresponde ao caminho completo") }
    var search: String { text("搜索", "搜尋", "Search", "検索", "검색", "Buscar", "Rechercher", "Suchen", "Buscar") }
    var previous: String { text("上一个", "上一個", "Previous", "前へ", "이전", "Anterior", "Précédent", "Zurück", "Anterior") }
    var next: String { text("下一个", "下一個", "Next", "次へ", "다음", "Siguiente", "Suivant", "Weiter", "Próximo") }
    var scanning: String { text("正在扫描", "正在掃描", "Scanning", "スキャン中", "스캔 중", "Escaneando", "Analyse en cours", "Scan läuft", "Escaneando") }
    var scanFinished: String { text("扫描结束", "掃描結束", "Scan finished", "スキャン完了", "스캔 완료", "Escaneo finalizado", "Analyse terminée", "Scan beendet", "Escaneamento concluído") }
    var revealHelp: String { text("双击打开文件所在的文件夹", "按兩下開啟檔案所在的資料夾", "Double-click to open the containing folder", "ダブルクリックして保存場所を開く", "이중 클릭하여 포함된 폴더 열기", "Haz doble clic para abrir la carpeta contenedora", "Double-cliquez pour ouvrir le dossier parent", "Doppelklicken, um den übergeordneten Ordner zu öffnen", "Clique duas vezes para abrir a pasta que contém o arquivo") }

    var alertTitle: String { text("无法完成操作", "無法完成操作", "Unable to Complete Operation", "操作を完了できません", "작업을 완료할 수 없음", "No se puede completar la operación", "Impossible de terminer l’opération", "Vorgang kann nicht abgeschlossen werden", "Não foi possível concluir a operação") }
    var dismiss: String { text("知道了", "好", "OK", "OK", "확인", "Aceptar", "OK", "OK", "OK") }
    var unknownError: String { text("发生未知错误。", "發生未知錯誤。", "An unknown error occurred.", "不明なエラーが発生しました。", "알 수 없는 오류가 발생했습니다.", "Se produjo un error desconocido.", "Une erreur inconnue s’est produite.", "Ein unbekannter Fehler ist aufgetreten.", "Ocorreu um erro desconhecido.") }
    var choosePanelTitle: String { text("选择要生成清单的文件夹", "選擇要產生清單的資料夾", "Choose a Folder to Generate a Manifest", "一覧を作成するフォルダを選択", "목록을 생성할 폴더 선택", "Elige una carpeta para generar el manifiesto", "Choisissez un dossier pour générer un manifeste", "Ordner für die Listenerstellung auswählen", "Escolha uma pasta para gerar o manifesto") }
    var startScan: String { text("开始扫描", "開始掃描", "Start Scan", "スキャン開始", "스캔 시작", "Iniciar escaneo", "Lancer l’analyse", "Scan starten", "Iniciar varredura") }
    var manifestCopied: String { text("清单已复制", "清單已複製", "Manifest copied", "一覧をコピーしました", "목록이 복사됨", "Manifiesto copiado", "Manifeste copié", "Liste kopiert", "Manifesto copiado") }
    var itemMissing: String { text("该项目可能已被移动或删除，请重新扫描文件夹。", "此項目可能已被移動或刪除，請重新掃描資料夾。", "The item may have been moved or deleted. Rescan the folder.", "項目が移動または削除された可能性があります。フォルダを再スキャンしてください。", "항목이 이동되었거나 삭제되었을 수 있습니다. 폴더를 다시 스캔하세요.", "Es posible que el elemento se haya movido o eliminado. Vuelve a escanear la carpeta.", "L’élément a peut-être été déplacé ou supprimé. Analysez à nouveau le dossier.", "Das Element wurde möglicherweise verschoben oder gelöscht. Scannen Sie den Ordner erneut.", "O item pode ter sido movido ou excluído. Escaneie a pasta novamente.") }
    var shownInFinder: String { text("已在 Finder 中显示", "已在 Finder 中顯示", "Shown in Finder", "Finderに表示しました", "Finder에 표시됨", "Mostrado en Finder", "Affiché dans le Finder", "Im Finder angezeigt", "Exibido no Finder") }
    var exportFilenameSuffix: String { text("目录清单", "目錄清單", "manifest", "フォルダ一覧", "폴더목록", "manifiesto", "manifeste", "Ordnerliste", "manifesto") }
    var exportPanelTitle: String { text("导出目录清单", "匯出目錄清單", "Export Folder Manifest", "フォルダ一覧を書き出す", "폴더 목록 내보내기", "Exportar manifiesto de carpeta", "Exporter le manifeste du dossier", "Ordnerliste exportieren", "Exportar manifesto da pasta") }
    var manifestExported: String { text("清单已导出", "清單已匯出", "Manifest exported", "一覧を書き出しました", "목록을 내보냈습니다", "Manifiesto exportado", "Manifeste exporté", "Liste exportiert", "Manifesto exportado") }

    func invalidRegex(_ detail: String) -> String { text("正则表达式无效：\(detail)", "正規表示式無效：\(detail)", "Invalid regular expression: \(detail)", "正規表現が無効です：\(detail)", "잘못된 정규식: \(detail)", "Expresión regular no válida: \(detail)", "Expression régulière non valide : \(detail)", "Ungültiger regulärer Ausdruck: \(detail)", "Expressão regular inválida: \(detail)") }
    func matchCount(_ count: Int) -> String { text("\(count) 个匹配", "\(count) 個相符項目", "\(count) matches", "\(count)件一致", "\(count)개 일치", "\(count) coincidencias", "\(count) correspondances", "\(count) Treffer", "\(count) correspondências") }
    func matchPosition(_ current: Int, total: Int) -> String { text("第 \(current) 个，共 \(total) 个匹配", "第 \(current) 個，共 \(total) 個相符項目", "Match \(current) of \(total)", "\(total)件中\(current)件目", "\(total)개 중 \(current)번째", "Coincidencia \(current) de \(total)", "Correspondance \(current) sur \(total)", "Treffer \(current) von \(total)", "Correspondência \(current) de \(total)") }
    func fileCount(_ count: Int) -> String { text("\(count) 个文件", "\(count) 個檔案", "\(count) files", "\(count)ファイル", "파일 \(count)개", "\(count) archivos", "\(count) fichiers", "\(count) Dateien", "\(count) arquivos") }
    func discoveredItems(_ count: Int) -> String {
        let value = formattedCount(count)
        return text("，已发现 \(value) 个项目", "，已發現 \(value) 個項目", ", discovered \(value) items", "、\(value)件を検出", ", \(value)개 항목 발견", ", se encontraron \(value) elementos", " : \(value) éléments trouvés", ", \(value) Elemente gefunden", ", \(value) itens encontrados")
    }

    func totalDiscoveredItems(_ count: Int) -> String {
        let value = formattedCount(count)
        return text("，共发现 \(value) 个项目", "，共發現 \(value) 個項目", ", \(value) items found in total", "、合計\(value)件", ", 총 \(value)개 항목", ", \(value) elementos en total", " : \(value) éléments au total", ", insgesamt \(value) Elemente", ", \(value) itens no total")
    }
    func exportFailure(_ detail: String) -> String { text("导出失败：\(detail)", "匯出失敗：\(detail)", "Export failed: \(detail)", "書き出しに失敗しました：\(detail)", "내보내기 실패: \(detail)", "Error de exportación: \(detail)", "Échec de l’export : \(detail)", "Export fehlgeschlagen: \(detail)", "Falha ao exportar: \(detail)") }
    func notFolderError() -> String { text("请选择一个文件夹，而不是单个文件。", "請選擇資料夾，而不是單一檔案。", "Choose a folder, not an individual file.", "ファイルではなくフォルダを選択してください。", "개별 파일이 아닌 폴더를 선택하세요.", "Elige una carpeta, no un archivo individual.", "Choisissez un dossier, pas un fichier individuel.", "Wählen Sie einen Ordner, keine einzelne Datei.", "Escolha uma pasta, não um arquivo individual.") }
    func unreadableError(_ name: String) -> String { text("无法读取“\(name)”。请确认文件夹仍然存在且具有访问权限。", "無法讀取「\(name)」。請確認資料夾仍然存在且具有存取權限。", "Unable to read “\(name)”. Make sure the folder still exists and you have permission to access it.", "「\(name)」を読み込めません。フォルダが存在し、アクセス権があることを確認してください。", "“\(name)”을(를) 읽을 수 없습니다. 폴더가 존재하고 접근 권한이 있는지 확인하세요.", "No se puede leer “\(name)”. Comprueba que la carpeta exista y que tengas permiso para acceder.", "Impossible de lire « \(name) ». Vérifiez que le dossier existe et que vous avez l’autorisation d’y accéder.", "„\(name)“ kann nicht gelesen werden. Prüfen Sie, ob der Ordner vorhanden ist und Sie Zugriffsrechte haben.", "Não foi possível ler “\(name)”. Verifique se a pasta existe e se você tem permissão de acesso.") }

    func sortName(_ sort: ManifestSort) -> String {
        switch sort {
        case .name: text("名称", "名稱", "Name", "名前", "이름", "Nombre", "Nom", "Name", "Nome")
        case .type: text("类型", "類型", "Type", "種類", "유형", "Tipo", "Type", "Typ", "Tipo")
        case .modified: modifiedDate
        case .size: text("大小", "大小", "Size", "サイズ", "크기", "Tamaño", "Taille", "Größe", "Tamanho")
        }
    }
}
