import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

bool _firebaseIsConfigured() {
  final options = DefaultFirebaseOptions.currentPlatform;
  return !options.apiKey.startsWith('YOUR_') &&
      !options.projectId.startsWith('YOUR_');
}

Future<void> _ensureFirebaseInitialized() async {
  if (!_firebaseIsConfigured()) {
    return;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureFirebaseInitialized();

  runApp(const RookieFoxApp());
}

class RookieFoxApp extends StatelessWidget {
  const RookieFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rookie Fox Dev Hub',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurpleAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_firebaseIsConfigured()) {
      return const LoginScreen();
    }

    return FutureBuilder<void>(
      future: _ensureFirebaseInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Erro ao inicializar Firebase: ${snapshot.error}'),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data != null) {
              return const HomeScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_firebaseIsConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure o Firebase antes de usar o login.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      final message = switch (e.code) {
        'user-not-found' => 'Nenhum usuário encontrado com este e-mail.',
        'wrong-password' => 'Senha incorreta. Tente novamente.',
        'invalid-email' => 'E-mail inválido.',
        'user-disabled' => 'Esta conta foi desativada.',
        _ => 'Não foi possível fazer login. Tente novamente.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Digite seu e-mail.';
    }

    final email = valor.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Digite sua senha.';
    }

    if (valor.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.games, size: 82, color: Colors.deepPurple),
                  const SizedBox(height: 20),
                  const Text(
                    'Rookie Fox Dev Hub',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Conectando pessoas e projetos de jogos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: _validarEmail,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: _validarSenha,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CadastroScreen(),
                        ),
                      );
                    },
                    child: const Text('Cadastre-se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirmacao = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_firebaseIsConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure o Firebase antes de criar a conta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _senhaController.text.trim();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      final message = switch (e.code) {
        'email-already-in-use' => 'Já existe uma conta com este e-mail.',
        'invalid-email' => 'E-mail inválido.',
        'weak-password' => 'A senha deve ser mais forte.',
        _ => 'Não foi possível concluir o cadastro. Tente novamente.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Digite seu e-mail.';
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(valor.trim())) {
      return 'Digite um e-mail válido.';
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Digite uma senha.';
    }

    if (valor.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }

    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirme sua senha.';
    }

    if (valor != _senhaController.text) {
      return 'As senhas não conferem.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 70,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Rookie Fox Dev Hub',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validarEmail,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _senhaController,
                  obscureText: _obscureSenha,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSenha ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSenha = !_obscureSenha;
                        });
                      },
                    ),
                  ),
                  validator: _validarSenha,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _confirmarSenhaController,
                  obscureText: _obscureConfirmacao,
                  decoration: InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmacao
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmacao = !_obscureConfirmacao;
                        });
                      },
                    ),
                  ),
                  validator: _validarConfirmacao,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cadastrar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cadastrar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _resetPassword() async {
    if (!_firebaseIsConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure o Firebase para redefinir a senha.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível localizar o e-mail desta conta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de redefinição enviado para $email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'user-not-found' => 'Nenhuma conta encontrada para este e-mail.',
        'invalid-email' => 'E-mail inválido.',
        _ => 'Não foi possível enviar a redefinição de senha.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    if (!_firebaseIsConfigured()) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair: ${e.message ?? 'Tente novamente.'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projetos = [
      {
        'titulo': 'Projetos de Jogos',
        'descricao': 'Explore projetos da comunidade.',
        'icone': Icons.games,
      },
      {
        'titulo': 'Equipes',
        'descricao': 'Encontre pessoas para trabalhar em projetos.',
        'icone': Icons.groups,
      },
      {
        'titulo': 'Eventos',
        'descricao': 'Participe de hackathons e encontros.',
        'icone': Icons.event,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rookie Fox Dev Hub'),
        actions: [
          IconButton(
            tooltip: 'Redefinir senha',
            icon: const Icon(Icons.lock_reset),
            onPressed: _resetPassword,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Perfil do usuário',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bem-vindo ao Rookie Fox Dev Hub!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Encontre projetos, participe de equipes e acompanhe o desenvolvimento de jogos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: projetos.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = projetos[index];

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          item['icone'] as IconData,
                          color: Colors.deepPurple,
                        ),
                        title: Text(item['titulo'] as String),
                        subtitle: Text(item['descricao'] as String),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConteudoScreen(
                                titulo: item['titulo'] as String,
                                descricao: item['descricao'] as String,
                                icone: item['icone'] as IconData,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConteudoScreen extends StatelessWidget {
  const ConteudoScreen({
    required this.titulo,
    required this.descricao,
    required this.icone,
    super.key,
  });

  final String titulo;
  final String descricao;
  final IconData icone;

  static const projetos = [
    {
      'nome': 'Aventura nas Estrelas',
      'tipo': 'Jogo indie',
      'descricao': 'Uma aventura espacial com exploração e desafios.',
      'status': 'Em desenvolvimento',
      'icone': Icons.sports_esports,
    },
    {
      'nome': 'LevelUp Studio',
      'tipo': 'Startup de games',
      'descricao': 'Estúdio independente criando experiências multiplayer.',
      'status': 'Procurando colaboradores',
      'icone': Icons.rocket_launch,
    },
    {
      'nome': 'GameHub Tools',
      'tipo': 'Ferramenta para desenvolvedores',
      'descricao': 'Organize ideias, tarefas e equipes em um só lugar.',
      'status': 'Ideia publicada',
      'icone': Icons.build,
    },
  ];

  static const equipes = [
    {
      'nome': 'Equipe Aventura Espacial',
      'projeto': 'Aventura nas Estrelas',
      'descricao': 'Equipe criando um jogo indie de exploração espacial.',
      'membros': '4 membros',
      'tecnologias': 'Unity, C# e Blender',
      'status': 'Aceitando colaboradores',
      'icone': Icons.groups,
    },
    {
      'nome': 'LevelUp Multiplayer',
      'projeto': 'LevelUp Studio',
      'descricao': 'Time focado em experiências multiplayer para PC.',
      'membros': '6 membros',
      'tecnologias': 'Godot, GDScript e Firebase',
      'status': 'Procurando artista',
      'icone': Icons.groups_2,
    },
    {
      'nome': 'Criadores GameHub',
      'projeto': 'GameHub Tools',
      'descricao': 'Pessoas desenvolvendo ferramentas para criadores de jogos.',
      'membros': '3 membros',
      'tecnologias': 'Flutter, Dart e GitHub',
      'status': 'Aberta para novos membros',
      'icone': Icons.group_add,
    },
  ];

  static const eventos = [
    {
      'nome': 'Encontro Rookie Fox',
      'tipo': 'Encontro da comunidade',
      'descricao': 'Conheça desenvolvedores, equipes e novos projetos.',
      'data': '21 de setembro de 2026',
      'horario': '19:00',
      'local': 'Online • Discord',
      'icone': Icons.groups,
    },
    {
      'nome': 'Game Jam 48 Horas',
      'tipo': 'Hackathon de jogos',
      'descricao': 'Crie um jogo em equipe a partir de um tema surpresa.',
      'data': '03 de outubro de 2026',
      'horario': '09:00',
      'local': 'São Paulo • Presencial',
      'icone': Icons.timer,
    },
    {
      'nome': 'Workshop de Unity',
      'tipo': 'Workshop',
      'descricao': 'Aprenda a criar uma cena jogável com Unity e C#.',
      'data': '10 de outubro de 2026',
      'horario': '14:00',
      'local': 'Online • Meet',
      'icone': Icons.school,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        child: titulo == 'Projetos de Jogos'
            ? _buildVitrineProjetos(context)
            : titulo == 'Equipes'
            ? _buildVitrineEquipes(context)
            : titulo == 'Eventos'
            ? _buildAgendaEventos(context)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: _buildIntroducao(),
              ),
      ),
    );
  }

  Widget _buildIntroducao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Icon(icone, size: 72, color: Colors.deepPurple)),
        const SizedBox(height: 24),
        Text(
          titulo,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(descricao, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 28),
        Text(_mensagemDaTela(titulo), style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildVitrineProjetos(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          'Projetos para conhecer',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jogos, startups e ferramentas publicados pela comunidade.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...projetos.map(
          (projeto) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9DDF7),
                child: Icon(
                  projeto['icone'] as IconData,
                  color: Colors.deepPurple,
                ),
              ),
              title: Text(
                projeto['nome'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${projeto['tipo']}\n${projeto['descricao']}\n\n${projeto['status']}',
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjetoDetalheScreen(
                      nome: projeto['nome'] as String,
                      tipo: projeto['tipo'] as String,
                      descricao: projeto['descricao'] as String,
                      status: projeto['status'] as String,
                      icone: projeto['icone'] as IconData,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitrineEquipes(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          'Equipes e projetos',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Encontre pessoas para criar jogos e colaborar em projetos.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...equipes.map(
          (equipe) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9DDF7),
                child: Icon(
                  equipe['icone'] as IconData,
                  color: Colors.deepPurple,
                ),
              ),
              title: Text(
                equipe['nome'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Projeto: ${equipe['projeto']}\n${equipe['descricao']}\n\n${equipe['membros']} • ${equipe['status']}',
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipeDetalheScreen(
                      nome: equipe['nome'] as String,
                      projeto: equipe['projeto'] as String,
                      descricao: equipe['descricao'] as String,
                      membros: equipe['membros'] as String,
                      tecnologias: equipe['tecnologias'] as String,
                      status: equipe['status'] as String,
                      icone: equipe['icone'] as IconData,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaEventos(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          'Agenda da comunidade',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Encontros, hackathons e workshops para aprender e criar juntos.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...eventos.map(
          (evento) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9DDF7),
                child: Icon(
                  evento['icone'] as IconData,
                  color: Colors.deepPurple,
                ),
              ),
              title: Text(
                evento['nome'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${evento['tipo']}\n${evento['data']} • ${evento['horario']}\n${evento['local']}',
                ),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventoDetalheScreen(
                      nome: evento['nome'] as String,
                      tipo: evento['tipo'] as String,
                      descricao: evento['descricao'] as String,
                      data: evento['data'] as String,
                      horario: evento['horario'] as String,
                      local: evento['local'] as String,
                      icone: evento['icone'] as IconData,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _mensagemDaTela(String titulo) {
    switch (titulo) {
      case 'Projetos de Jogos':
        return 'Aqui você poderá conhecer e acompanhar projetos de jogos da comunidade.';
      case 'Equipes':
        return 'Aqui você poderá encontrar pessoas e formar equipes para seus projetos.';
      case 'Eventos':
        return 'Aqui você poderá conferir hackathons, encontros e próximos eventos.';
      default:
        return 'Confira as novidades da comunidade Rookie Fox Dev Hub.';
    }
  }
}

class ProjetoDetalheScreen extends StatelessWidget {
  const ProjetoDetalheScreen({
    required this.nome,
    required this.tipo,
    required this.descricao,
    required this.status,
    required this.icone,
    super.key,
  });

  final String nome;
  final String tipo;
  final String descricao;
  final String status;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Icon(icone, size: 76, color: Colors.deepPurple)),
          const SizedBox(height: 24),
          Text(
            nome,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(tipo, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 20),
          Text(descricao, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Chip(avatar: const Icon(Icons.info_outline), label: Text(status)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Interesse registrado!')),
              );
            },
            icon: const Icon(Icons.favorite_border),
            label: const Text('Tenho interesse'),
          ),
        ],
      ),
    );
  }
}

class EquipeDetalheScreen extends StatelessWidget {
  const EquipeDetalheScreen({
    required this.nome,
    required this.projeto,
    required this.descricao,
    required this.membros,
    required this.tecnologias,
    required this.status,
    required this.icone,
    super.key,
  });

  final String nome;
  final String projeto;
  final String descricao;
  final String membros;
  final String tecnologias;
  final String status;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Icon(icone, size: 76, color: Colors.deepPurple)),
          const SizedBox(height: 24),
          Text(
            nome,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Projeto: $projeto', style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 20),
          Text(descricao, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          _InfoEquipe(icone: Icons.people, titulo: 'Membros', valor: membros),
          _InfoEquipe(
            icone: Icons.code,
            titulo: 'Tecnologias',
            valor: tecnologias,
          ),
          _InfoEquipe(
            icone: Icons.info_outline,
            titulo: 'Status',
            valor: status,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pedido para entrar enviado!')),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Quero entrar na equipe'),
          ),
        ],
      ),
    );
  }
}

class _InfoEquipe extends StatelessWidget {
  const _InfoEquipe({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icone, color: Colors.deepPurple),
        title: Text(titulo),
        subtitle: Text(valor),
      ),
    );
  }
}

class EventoDetalheScreen extends StatelessWidget {
  const EventoDetalheScreen({
    required this.nome,
    required this.tipo,
    required this.descricao,
    required this.data,
    required this.horario,
    required this.local,
    required this.icone,
    super.key,
  });

  final String nome;
  final String tipo;
  final String descricao;
  final String data;
  final String horario;
  final String local;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Icon(icone, size: 76, color: Colors.deepPurple)),
          const SizedBox(height: 24),
          Text(
            nome,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(tipo, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 20),
          Text(descricao, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          _InfoEvento(icone: Icons.calendar_month, titulo: 'Data', valor: data),
          _InfoEvento(icone: Icons.schedule, titulo: 'Horário', valor: horario),
          _InfoEvento(icone: Icons.location_on, titulo: 'Local', valor: local),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Presença confirmada!')),
              );
            },
            icon: const Icon(Icons.event_available),
            label: const Text('Confirmar presença'),
          ),
        ],
      ),
    );
  }
}

class _InfoEvento extends StatelessWidget {
  const _InfoEvento({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icone, color: Colors.deepPurple),
        title: Text(titulo),
        subtitle: Text(valor),
      ),
    );
  }
}

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nomeController = TextEditingController(text: 'João da Silva');
  final _emailController = TextEditingController(text: 'usuario@rookiefox.dev');
  final _contatoController = TextEditingController(text: '(11) 99999-0000');
  final _githubController = TextEditingController(text: 'github.com/joaosilva');
  final _cpfController = TextEditingController(text: '123.***.***-00');
  final _cidadeController = TextEditingController(text: 'São Paulo, SP');
  bool _editando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _contatoController.dispose();
    _githubController.dispose();
    _cpfController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  void _salvarPerfil() {
    if (_nomeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha nome e e-mail.')));
      return;
    }

    setState(() {
      _editando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            tooltip: _editando ? 'Cancelar edição' : 'Editar perfil',
            icon: Icon(_editando ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _editando = !_editando),
          ),
        ],
      ),
      body: SafeArea(
        child: _editando
            ? _buildFormularioEdicao()
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.person, color: Colors.white, size: 56),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _nomeController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(child: Text('Desenvolvedor de jogos')),
                  const SizedBox(height: 28),
                  _PerfilItem(
                    icone: Icons.badge_outlined,
                    titulo: 'Nome completo',
                    valor: _nomeController.text,
                  ),
                  _PerfilItem(
                    icone: Icons.email_outlined,
                    titulo: 'E-mail',
                    valor: _emailController.text,
                  ),
                  _PerfilItem(
                    icone: Icons.phone_outlined,
                    titulo: 'Contato',
                    valor: _contatoController.text,
                  ),
                  _PerfilItem(
                    icone: Icons.code,
                    titulo: 'GitHub',
                    valor: _githubController.text,
                  ),
                  _PerfilItem(
                    icone: Icons.fingerprint,
                    titulo: 'CPF',
                    valor: _cpfController.text,
                  ),
                  _PerfilItem(
                    icone: Icons.location_on_outlined,
                    titulo: 'Cidade',
                    valor: _cidadeController.text,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormularioEdicao() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, color: Colors.white, size: 56),
          ),
        ),
        const SizedBox(height: 24),
        _campo('Nome completo', _nomeController, Icons.badge_outlined),
        _campo('E-mail', _emailController, Icons.email_outlined),
        _campo('Contato', _contatoController, Icons.phone_outlined),
        _campo('GitHub', _githubController, Icons.code),
        _campo('CPF', _cpfController, Icons.fingerprint),
        _campo('Cidade', _cidadeController, Icons.location_on_outlined),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _salvarPerfil,
            icon: const Icon(Icons.save),
            label: const Text('Salvar perfil'),
          ),
        ),
      ],
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller,
    IconData icone,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icone)),
      ),
    );
  }
}

class _PerfilItem extends StatelessWidget {
  const _PerfilItem({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icone, color: Colors.deepPurple),
        title: Text(titulo),
        subtitle: Text(valor),
      ),
    );
  }
}
