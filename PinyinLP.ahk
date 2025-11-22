class PinyinLP {
    static filePath := "pinyin_lenprefix.bin"
    static bufPtr := 0
    static bufObj := ""
    static inited := false
    static dataStart := 0

    static Init(path := "") {
        if path != ""
            PinyinLP.filePath := path

        raw := FileRead(PinyinLP.filePath, "RAW")
    
        if IsObject(raw) {
            if raw.Size = 0
                throw Error("无法读取文件 " PinyinLP.filePath)
            PinyinLP.bufObj := raw
            PinyinLP.bufPtr := raw.Ptr
        } else {
            if raw = ""
                throw Error("无法读取文件 " PinyinLP.filePath)
            size := StrLen(raw)
            buf := Buffer(size)
            DllCall("RtlMoveMemory", "Ptr", buf.Ptr, "Str", raw, "UPtr", size)
            PinyinLP.bufObj := buf
            PinyinLP.bufPtr := buf.Ptr
        }

        ; 校验 Magic
        magic := ""
        Loop 4
            magic .= Chr(NumGet(PinyinLP.bufPtr, A_Index-1, "UChar"))
        if magic != "PYLP"
            throw Error("Magic 错误，文件格式不匹配")

        PinyinLP.dataStart := 8 + 65536 * 4
        PinyinLP.inited := true
    }

    static Get(ch) {
        if !PinyinLP.inited
            PinyinLP.Init()

        if StrLen(ch) < 1
            return []

        cp := Ord(ch)
        if cp >= 0x10000
            return []

        idxPos := 8 + cp * 4
        off := NumGet(PinyinLP.bufPtr, idxPos, "UInt")
        if off = 0
            return []

        len := NumGet(PinyinLP.bufPtr, off, "UShort")

        ptrData := PinyinLP.bufPtr + off + 2

        txt := StrGet(ptrData, len, "UTF-8")
        return InStr(txt,',') ? StrSplit(txt, ",") : txt
    }
