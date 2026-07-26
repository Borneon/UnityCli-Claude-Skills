# Derinlemesine sorun giderme

SKILL.md'deki arıza ağacı belirtiyi doğrudan çözmüyorsa buradaki yöntemle
ilerle. Temel fikir: Claude Code → `unity mcp` → editör içindeki Pipeline
sunucusu bir zincirdir; arıza çoğu zaman tek halkadadır ama belirti üç
halkayı da suçlu gösterir. Suçluyu tahminle değil deneyle bul.

## 1. Zinciri katmanlara ayır

Takılan halkanın konuştuğu servise aracıyı atlayıp doğrudan bağlan:

```bash
PORT_FILE=<proje>/Library/Pipeline/.unity-pipeline-port
cat "$PORT_FILE"                  # pid, port, projectPath, evalToken
curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://127.0.0.1:<port>/
```

Yorumlama kuralı: **bir bileşen takılıyor ama alttaki servis hızlı cevap
veriyorsa, suçlu istemcidir.** 401 bile iyi haberdir; sunucunun ayakta olup
kimlik istediğini gösterir. Cevap hiç gelmiyorsa sorun sunucu tarafındadır
(editör kapalı, Pipeline kurulmamış ya da import sürüyor).

## 2. Ham JSON-RPC ile cevapsız metodu bul

`unity mcp` sunucusuyla stdio üzerinden elle konuş:

```bash
{
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"diag","version":"1.0"}}}'
printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/initialized"}'
printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
sleep 8
} | timeout -k 3 25 unity mcp 2>&1 | tail -20
```

- `initialize` cevap veriyor, `tools/list` gelmiyorsa: sunucu yaşıyor ama
  editör sorgusu kilitleniyor. Bu örüntü tipik olarak istemci/CLI sürüm
  hatasıdır; sağlık kontrolleri "Connected" gösterir çünkü el sıkışma
  çalışmaktadır.
- İkisi de geliyorsa köprü sağlamdır; sorun Claude Code tarafındadır
  (açılış sıralaması, kayıt).

## 3. Takılan komutları daima sar

Teşhis sırasında her şüpheli komutu zaman aşımıyla çalıştır:

```bash
timeout -k 5 15 unity status
```

`-k` (SIGKILL) şarttır: hatalı bir CLI süreci SIGTERM'i yutabilir ve
`timeout` tek başına kurtarmaz. Sarmadan çalıştırılıp takılan tek bir komut,
teşhis oturumunu dakikalarca kilitleyebilir.

## 4. Genellikle masum çıkan şüpheliler

"Editörle konuşan her istek takılı kalıyor" belirtisinde akla ilk gelen şu
dört sebep, tek tek doğrulanmadan suçlanmamalıdır; sıklıkla hepsi masumdur
ve gerçek sebep istemci sürümüdür (SKILL.md'deki sürüm kuralı):

- **`-automated` eksikliği.** Pipeline log'u bu yönde uyarı basar ve bayrak
  gerçekten gereklidir (modal koruması). Ancak bayrağı ekleyip belirtinin
  DEĞİŞİP değişmediğini ölçmeden "çözüldü" sayma: bir düzeltmenin gerekli
  olması, onu eldeki arızanın sebebi yapmaz.
- **Editör meşgul (import/derleme).** Meşguliyet iddiasını hisle değil
  kanıtla ele: `pgrep -f AssetImportWorker` boşaldıktan sonra belirti
  sürüyorsa sebep bu değildir.
- **Bayat oturum.** `unity doctor` çıktısındaki `auth.sessionState: stale`
  inandırıcı görünür; `unity auth login` ile tazeleyip belirtiyi yeniden
  ölç. Değişmiyorsa elendi.
- **Kayıtta eksik proje yolu.** `--project-path` sabitlemesi zararsızdır ama
  bağlantı arızalarının tipik sebebi değildir; ekleyip sonucu ölç, düzelme
  yoksa iz kapandı demektir.

Genel disiplin: her hipotez için onu tek başına sınayan ayırt edici bir
deney kur ve iki değişikliği asla aynı anda yapma. Aksi hâlde hangi
değişikliğin ne yaptığı bilinemez ve masum bileşenlerde gereksiz
yapılandırma birikir.

## 5. Geçici 401: token rotasyonu

Editördeki her domain reload (script derlemesi) `.unity-pipeline-port`
dosyasındaki `evalToken`'ı yeniler. O ana denk gelen MCP isteği
`401 Unauthorized` alır. Bu kalıcı arıza değildir: birkaç saniye bekleyip
aynı isteği tekrarla. Yeniden kurulum ya da yeniden kayıt gerekmez.

## 6. Yalancı başarıya inanma

Menü tetikleyen bir MCP çağrısı `success: true` dönebilir ama iş, editörde
açılan bir onay penceresine takılmış olabilir (modal, ana thread'i kilitler
ve komut kanalını cevapsız bırakır). Sonucu dönüş mesajından değil,
gözlenebilir etkiden doğrula: hedef dosyanın zaman damgası ilerledi mi,
sahnede beklenen nesne `find_gameobjects` ile bulunuyor mu?

## 7. Ekran görüntüsü kanıt değildir, ölçüm kanıttır

Render edilen kare gerçek ekran boyutundan ve ölçeğinden farklı olabilir;
görsel çıktı yanıltır. UI/sahne doğrularken önce `eval` ile sayı ölç
(koordinat, adet, mesafe), görüntüyü ancak ölçümü doğruladıktan sonra
yorumla. RectTransform ölçümlerinde `GetWorldCorners` dünya koordinatı
döndürür; `Screen.height` ile değil, canvas uzayına çevirip canvas'ın kendi
`rect`'iyle karşılaştır.
