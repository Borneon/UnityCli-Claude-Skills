---
name: unity-mcp
description: Unity Editor'ı Claude Code'dan canlı kontrol etmek için kurulum, bağlanma ve arıza giderme rehberi (Unity CLI + Pipeline paketi + MCP köprüsü). Bir Unity projesinde editörü kontrol etmek, sahneyi yeniden kurmak, Play modunda ölçüm ya da ekran görüntüsü almak, konsolu okumak, testleri koşturmak veya MCP bağlantısını kurmak/onarmak gerektiğinde kullan. "Unity'yi bağla", "MCP kur", "sahneyi yeniden kur", "editörde çalıştır/doğrula", "araçlar gelmiyor", "unity status takılıyor", "tools fetch failed" gibi taleplerde kullanıcı skill'den söz etmese bile tetiklen.
---

# Unity Editor'ı Claude Code'dan Kontrol Etmek

Üç parça üst üste durur; biri eksikse zincir kopar:

```
Claude Code  ──stdio──▶  unity mcp (CLI)  ──HTTP :7800──▶  Pipeline paketi (Editor içinde)
   araçlar                 köprü süreci                      komut sunucusu
```

- **Unity CLI** (`~/.unity/bin/unity`) — makine başına bir kez kurulur.
- **`com.unity.pipeline`** — **proje başına** kurulur; editörün içinde HTTP sunucusu açar.
- **MCP kaydı** — Claude Code'a `unity-editor-mcp` sunucusunu tanıtır.

Bağlanınca `mcp__unity-editor-mcp__*` araçları gelir (~139 adet). Şema yüklü
gelmez; `ToolSearch` ile `select:mcp__unity-editor-mcp__<ad>,...` diyerek
ihtiyacın olanları **tek çağrıda** yükle.

---

## ⛓ Altın kural: sıralama

**Editör `-automated` ile AÇIK olmalı, Claude Code ondan SONRA başlamalı.**

MCP araç listesi Claude Code açılışında bir kez sayılır. Editör kapalıysa
`unity mcp` bağlanacak bir şey bulamaz, **sıfır araç** yayınlar ve oturumda
hiçbir Unity aracı görünmez. `claude mcp list` yine "Connected" der — aldatıcıdır.

Doğru sıra:

```bash
unity open --args "-automated" /yol/proje    # 1) editörü aç
unity status                                  # 2) "ready" satırı çıkana kadar bekle
# 3) sonra Claude Code'u başlat / reset at (claude --continue)
```

`-automated` şart: onsuz modal pencereler editörün ana thread'ini kilitler ve
komut kanalı cevapsız kalır.

---

## Kurulum — makine başına bir kez

```bash
unity --version           # 1.0.0-beta.3 ve ÜSTÜ olmalı
unity upgrade --check     # yeni sürüm var mı
unity upgrade -y          # güncelle (geri alma: unity upgrade --rollback)
unity auth status         # giriş yapılmış olmalı
```

> **`beta.2` kullanma.** O sürümde editörle konuşan *her* istek sessizce takılı
> kalır: `unity status`, `unity command`, MCP `tools/list`. `initialize` cevap
> verdiği için sağlıklı görünür ama araç listesi hiç gelmez ve belirti, saatlerce
> yanlış yerde aratabilir. **Arıza aramaya başlamadan önce sürümü kontrol et.**

MCP kaydını yaz:

```bash
unity mcp configure claude-code --yes
```

Bu şunu çalıştırır: `claude mcp add --scope user --transport stdio unity-editor-mcp unity mcp`

Kayıt zaten varsa `claude mcp add` üstüne yazmaz, hata verir. Önce sil:

```bash
claude mcp remove unity-editor-mcp --scope user
```

`--project-path <yol>` ile belirli bir projeye sabitleyebilirsin, ama
**gerekli değildir**; sabitlemeden bırakırsan hangi proje açıksa ona bağlanır.
(Sabitleme, bağlantı arızalarının sebebi de çözümü de değildir; yalnızca hedefi
tek projeye kilitlemek istediğinde kullan.)

## Kurulum — proje başına bir kez

```bash
unity pipeline install --project-path /yol/proje
unity pipeline list-versions       # mevcut sürümler (deneysel: 0.3.x-exp)
```

Paket `manifest.json`'a girer; `packages-lock.json` editör ilk açılışta
güncellenir. İlk açılış büyük bir reimport tetikleyebilir — **bitmesini bekle**,
sunucu ondan önce cevap vermez.

Zararsız uyarı: `System.Runtime.CompilerServices.Unsafe` sürüm çakışması
("ignoring"). Görmezden gel.

---

## Bağlantıyı doğrula

```bash
unity status                       # 7800 / ready / <proje> / <sürüm> / <pid>
unity pipeline list                # Running=true, Server Reachable=true
claude mcp list | grep unity       # "✔ Connected"  (tools fetch failed OLMAMALI)
```

CLI'ye hiç güvenmeden köprüyü sınamak (en güvenilir yöntem):

```bash
PORT_FILE=/yol/proje/Library/Pipeline/.unity-pipeline-port
cat "$PORT_FILE"                   # pid, port, projectPath, evalToken
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:7800/
#   401 → sunucu AYAKTA (kimlik istiyor) = sağlıklı
#   bağlanamıyor → sunucu yok
TOKEN=$(python3 -c "import json;print(json.load(open('$PORT_FILE'))['evalToken'])")
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" http://127.0.0.1:7800/
#   404 → kimlik doğrulama GEÇTİ (yol yanlış, önemi yok) = köprü tam sağlıklı
```

---

## Arıza ağacı

| Belirti | Sebep | Çözüm |
|---|---|---|
| Oturumda hiç `mcp__unity-editor-mcp__*` yok | Editör Claude Code'dan **sonra** açıldı ya da hiç açık değil | Editörü `-automated` ile aç, `unity status` "ready" desin, **sonra** Claude Code'u yeniden başlat |
| `claude mcp list` → `! Connected · tools fetch failed` | CLI **beta.2** | `unity upgrade -y` |
| `unity status` dakikalarca takılı, SIGTERM'e yanıt yok | CLI **beta.2** | `unity upgrade -y`. Teşhis sırasında hep `timeout -k 5 15 unity status` ile sar |
| MCP aracı `401 Unauthorized` | Domain reload token'ı döndürdü | **Geçici** — birkaç saniye sonra kendiliğinden düzelir, komutu tekrarla |
| Menü komutu "success" dönüyor ama hiçbir şey olmuyor | Editör aracı modal diyalog açtı, ana thread kilitli | Aracı `Unattended` ile koru (aşağı bak) |
| Editör açık ama sunucu yok | Pipeline paketi kurulu değil ya da ilk import sürüyor | `unity pipeline install`; import bitene kadar bekle |
| `capture_game_view` UI'yi göstermiyor | Screen Space **Overlay** canvas kameraya render olmaz | Canvas'ı geçici `ScreenSpaceCamera`'ya alan bir editör aracı kullan (aşağı bak) |

---

## Çalışan kalıplar

### 1. Ekran görüntüsüne değil, ölçüme güven

`eval` bu kurulumun asıl silahıdır — editör içinde rastgele C# çalıştırır.
Ekran görüntüsü yanıltabilir (render hedefi gerçek ekran boyutundan farklıdır);
sayı yanıltmaz.

```csharp
// eval NOTLARI:
// - son satır mutlaka `return ...;` olmalı, yalın ifade CS1002 verir
// - Unity 6: FindObjectsByType<T>(FindObjectsInactive.Include, FindObjectsSortMode.None)
// - private alanlara reflection ile eriş (BindingFlags.NonPublic | Instance)
```

**UI ölçerken en sık hata:** `GetWorldCorners` dünya koordinatı döndürür
(canvas `scaleFactor`'ü içerir); bunu `Screen.height` ile karşılaştırmak
yanlıştır. Canvas uzayına çevir, canvas'ın kendi `rect`'iyle kıyasla:

```csharp
var crt = (RectTransform)canvas.transform;
var c = new Vector3[4]; hedef.GetWorldCorners(c);
var altSol = crt.InverseTransformPoint(c[0]);
var ustSag = crt.InverseTransformPoint(c[2]);
bool siğiyor = altSol.x >= crt.rect.xMin && ustSag.x <= crt.rect.xMax
            && altSol.y >= crt.rect.yMin && ustSag.y <= crt.rect.yMax;
```

### 2. Sahne bayat mı? GUID'e bak

Kodla üretilen sahnelerde en sinsi hata: kod doğru, testler yeşil, ama sahne
eski. Sahne yeniden kurulmadıysa değişiklik ekranda görünmez.

```bash
GUID=$(grep -m1 "guid:" Assets/Scripts/.../YeniBilesen.cs.meta | awk '{print $2}')
grep -c "$GUID" Assets/Scenes/Main.unity     # 0 ise sahne BAYAT
```

MCP tarafında karşılığı: `find_gameobjects` ile `type: YeniBilesen` ara,
`count: 0` geliyorsa sahneyi yeniden kur.

### 3. Doğrulama döngüsü

```
menu(sahneyi kur) → editor_play → eval(ölç) → sahne fotoğrafı → editor_stop
                                → get_console_logs(severity: error)
```

Play modunda ölç: edit modunda `Start()` koşmadığı için UI yer tutucu
değerler gösterir (ham enum adları, panel açık görünmesi vb.) — bu **hata değil**.

---

## Editör aracı yazma konvansiyonu

Kodla sahne/asset üreten her editör aracı, ajan tarafından kontrol edilebilir olmalı.
Modal diyalog komut kanalını kilitler, o yüzden gözetimsiz modda sorma:

```csharp
/// Onay yalnız insanın önündeki editörde sorulur. Batch modda ve editör
/// -automated ile açıldığında (CLI/MCP ajanı kontrol ediyor) sorulmaz: modal pencere
/// editörün ana thread'ini kilitler, komut kanalı cevapsız kalır.
private static bool Unattended =>
    Application.isBatchMode ||
    System.Array.IndexOf(System.Environment.GetCommandLineArgs(), "-automated") >= 0;

[MenuItem("Proje/Sahneyi Kur")]
public static void BuildScene()
{
    if (!Unattended && !EditorUtility.DisplayDialog(...)) return;
    ...
}
```

İnsan koruması aynen kalır, ajan takılmaz.

**Ekran görüntüsü aracı** için de kalıp: Overlay canvas kameraya render olmaz,
çekim sırasında geçici olarak `RenderMode.ScreenSpaceCamera`'ya al, bitince eski
hâline döndür. PNG'yi `Path.GetTempPath()` altına yaz (projeye çöp bırakma).

---

## MCP'siz de iş görür

Köprü kurulmasa bile batch-mode her zaman çalışır — kurulum gerektirmez,
her Unity sürümüyle uyumludur:

```bash
Unity -projectPath <proje> -batchmode -quit -accept-apiupdate -logFile out.log
Unity -projectPath <proje> -batchmode -quit -executeMethod Ad.Alani.Sinif.Metot -logFile out.log
```

Sürüm yükseltme, sahne üretme, ekran görüntüsü alma — hepsi bu yolla yapılabilir.
MCP bunu **interaktif** hâle getirir; olmazsa olmaz değildir.

Derinlemesine teşhis (katman ayırma, ham JSON-RPC ile cevapsız metodu bulma,
sık görülen yanlış izler): `references/sorun-giderme.md`.
