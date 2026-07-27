# Unity-MCP Skill  Claude Code

Unity Editorünü Unity CLI yardımıyla MCP üzerinden Claude Code ile kontrol edebilmek için bir Claude Code skill
kurulum, bağlanma ve arıza giderme rehberi (Unity CLI + Pipeline paketi + MCP
bağlantısı). Skill devreye girince Claude code sahneyi yeniden kurabilir, Play modunda
ölçüm/ekran görüntüsü alabilir, konsolu okuyabilir ve MCP bağlantısını
kurup onarabilir.

## Ne işe yarar

- Unity CLI + `com.unity.pipeline` + MCP köprüsünün **sıfırdan kurulumu**
- "Araçlar gelmiyor / `tools fetch failed` / `unity status` takılıyor / 401"
  gibi tipik arızaların **belirti → sebep → çözüm** tablosu
- Editör araçlarını (sahne üretme vb.) ajanla sürülebilir yazma konvansiyonu
- Ekran görüntüsü yerine `eval` ile **ölçerek** doğrulama kalıpları

## Gereksinimler

- **Claude Code** (bu bir Claude Code skill'idir)
- **Unity CLI** `1.0.0-beta.3` veya üstü — `unity upgrade --check`
  (beta.2'de köprü sorun çıkarabiliyor, skill bu konuda sizi ilk sırada uyarır)
  Sürüm olarak Unity 6 ve üzerinde olmalısınız
  (kurulumu skill anlatır)

## Kurulum (plug and play)

### En hızlısı — git clone
```bash
git clone https://github.com/Borneon/claude-skills-unitycli.git
cd claude-skills-unitycli
./install.sh          # Windows'ta: install.ps1
```
Güncelleme geldiğinde: `git pull` + `./install.sh` tekrar.

### macOS / Linux
```bash
./install.sh
```
İzin hatası alırsan önce: `chmod +x install.sh`

### Windows
`install.ps1` dosyasına sağ tıkla → **PowerShell ile çalıştır**.
Engellenirse PowerShell'de: `Set-ExecutionPolicy -Scope Process Bypass`

### Elle (betik çalışmazsa)
`unity-mcp` klasörünü şuraya kopyala:
- macOS / Linux: `~/.claude/skills/`
- Windows: `%USERPROFILE%\.claude\skills\`

## Kurulum sonrası

1. **Claude Code'u yeniden başlat** (skill'ler açılışta yüklenir).
2. Skill kendiliğinden tetiklenir; ayrıca elle çağırmak için: `/unity-mcp`
3. Doğrulama: yeni bir Unity işinde "MCP'yi kur" dediğinde Claude adım adım
   yönlendirir.

## İçindekiler

```
unity-mcp/
├── SKILL.md                       Ana rehber (kurulum + kalıplar + arıza ağacı)
└── references/sorun-giderme.md    Derinlemesine teşhis (katman ayırma, ham
                                   JSON-RPC, sık görülen yanlış izler)
```

## Sürüm notu

İçerik Unity `6000.3.20f1`, Unity CLI `1.0.0-beta.3`, macOS 27 Developer Beta 4 arm64 üzerinde
doğrulanmıştır (2026-07). Bu araçlar beta komut/davranış değişirse önce
`unity upgrade --check` ile CLI'yi güncelle.
