/// AquaGuard - Kayıt/Giriş Ekranı (E-posta/Şifre Hesabı)
/// ============================================================
///
/// Amaç:
///   Firebase yapılandırıldıysa (bkz. config/firebase_secenekleri.dart)
///   ve oturum açık değilse `main.dart`'taki yönlendirici tarafından,
///   Onboarding'den sonra ve mevcut Giriş Ekranı'ndan (marka + Demo Modu
///   seçimi) ÖNCE gösterilir. Tek ekranda "Giriş Yap"/"Kayıt Ol" arası
///   geçiş yapılabilir.
///
///   DÜRÜSTLÜK NOTU (ekranda da gösterilir): bu hesap sadece giriş/çıkışı
///   yönetir, çiftlik/sensör verisi hesaba göre AYRILMAZ -- hâlâ tek
///   cihazda yerel olarak tutulur.
///
///   JÜRİ DEMOSU GÜVENLİĞİ: "Misafir olarak devam et" -- saha
///   ağı/Firebase'e erişim anlık kesilirse demo asla bloklanmaz.
///
/// Tarih:  2026-09-25
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../providers/kimlik_dogrulama_provider.dart';
import '../widgets/duyarli_icerik.dart';

class KayitGirisEkrani extends StatefulWidget {
  const KayitGirisEkrani({super.key});

  @override
  State<KayitGirisEkrani> createState() => _KayitGirisEkraniState();
}

class _KayitGirisEkraniState extends State<KayitGirisEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _epostaDenetci = TextEditingController();
  final _sifreDenetci = TextEditingController();
  final _sifreTekrarDenetci = TextEditingController();
  bool _kayitModuMu = false;
  bool _sifreGorunur = false;

  @override
  void dispose() {
    _epostaDenetci.dispose();
    _sifreDenetci.dispose();
    _sifreTekrarDenetci.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formAnahtari.currentState!.validate()) return;
    final kimlik = context.read<KimlikDogrulamaProvider>();
    final basarili = _kayitModuMu
        ? await kimlik.kayitOl(_epostaDenetci.text.trim(), _sifreDenetci.text)
        : await kimlik.girisYap(
            _epostaDenetci.text.trim(),
            _sifreDenetci.text,
          );
    // basarisizsa hataMesaji zaten build()'de gosterilecek -- burada ekstra
    // bir sey yapmaya gerek yok, basariliysa girisGerekliMi false'a
    // dusecegi icin main.dart'taki yonlendirici otomatik gecis yapar.
    if (!basarili) return;
  }

  @override
  Widget build(BuildContext context) {
    final kimlik = context.watch<KimlikDogrulamaProvider>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AquaGuardTema.anaRenk, AquaGuardTema.arkaPlanRenk],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: DuyarliIcerik(
              maksimumGenislik: 440,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formAnahtari,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _kayitModuMu ? 'Hesap Oluştur' : 'Giriş Yap',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6ECF1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Çiftlik/sensör verisi bu cihazda yerel kalır — '
                        'hesap sadece giriş/çıkışı yönetir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AACBC),
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _epostaDenetci,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (deger) {
                          final v = deger?.trim() ?? '';
                          if (v.isEmpty) return 'E-posta girin';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Geçerli bir e-posta girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sifreDenetci,
                        obscureText: !_sifreGorunur,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _sifreGorunur
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _sifreGorunur = !_sifreGorunur),
                          ),
                        ),
                        validator: (deger) {
                          if ((deger ?? '').length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      if (_kayitModuMu) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sifreTekrarDenetci,
                          obscureText: !_sifreGorunur,
                          decoration: const InputDecoration(
                            labelText: 'Şifre (Tekrar)',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (deger) {
                            if (deger != _sifreDenetci.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (kimlik.hataMesaji != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  kimlik.hataMesaji!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: kimlik.yukleniyor ? null : _gonder,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: kimlik.yukleniyor
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_kayitModuMu ? 'Kayıt Ol' : 'Giriş Yap'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: kimlik.yukleniyor
                            ? null
                            : () => setState(() => _kayitModuMu = !_kayitModuMu),
                        child: Text(
                          _kayitModuMu
                              ? 'Zaten hesabınız var mı? Giriş yapın'
                              : 'Hesabınız yok mu? Kayıt olun',
                        ),
                      ),
                      const Divider(height: 32, color: Color(0x339AACBC)),
                      OutlinedButton(
                        onPressed: kimlik.yukleniyor
                            ? null
                            : () => context
                                  .read<KimlikDogrulamaProvider>()
                                  .misafirOlarakDevamEt(),
                        child: const Text('Misafir olarak devam et'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
