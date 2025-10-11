# Ferrous CI/CD テストスイート

このディレクトリには、Ferrous CI/CDシステムの包括的な統合テストが含まれています。

## 📋 テスト概要

### テストファイル構成

```
tests/
├── README.md              # このファイル
├── common/
│   └── mod.rs            # 共通テストユーティリティとフィクスチャ
├── e2e/
│   ├── mod.rs            # E2Eテストユーティリティ
│   └── README.md         # E2Eテスト詳細ドキュメント
├── e2e_tests.rs           # 本番環境を模したE2Eテスト
├── integration_test.rs    # 基本的な統合テストとE2Eワークフロー
├── pipeline_tests.rs      # パイプライン機能のテスト
├── build_tests.rs         # ビルド実行のテスト
├── agent_tests.rs         # エージェント管理のテスト
├── event_tests.rs         # イベントシステムのテスト
└── stress_tests.rs        # 負荷テストとパフォーマンステスト
```

## 🧪 テストカテゴリ

### 1. 統合テスト (`integration_test.rs`)

基本的なシステム初期化とエンドツーエンドのワークフローをテストします。

```bash
cargo test --test integration_test
```

**テストケース:**
- システム初期化
- デフォルト設定の検証
- 完全なCI/CDワークフロー（プロジェクト作成→パイプライン作成→エージェント登録→ビルド実行）

### 2. パイプラインテスト (`pipeline_tests.rs`)

パイプラインの作成、設定、管理機能をテストします。

```bash
cargo test --test pipeline_tests
```

**テストケース:**
- パイプラインの作成と取得
- パイプラインの有効化/無効化
- パイプライン設定の更新
- プロジェクトパイプラインの一覧取得
- パイプライン設定のバリデーション

### 3. ビルドテスト (`build_tests.rs`)

ビルドのライフサイクルと実行フローをテストします。

```bash
cargo test --test build_tests
```

**テストケース:**
- 完全なビルドライフサイクル（作成→開始→完了）
- ビルドの失敗処理
- ビルドのキャンセル
- 同一パイプラインでの複数ビルド
- 並行ビルドの実行

### 4. エージェントテスト (`agent_tests.rs`)

エージェントの登録、管理、ジョブ割り当てをテストします。

```bash
cargo test --test agent_tests
```

**テストケース:**
- エージェントの登録とハートビート
- ジョブの割り当てと解放
- エージェントの切断
- 複数エージェントの管理
- デッドエージェントのクリーンアップ
- 重複登録のエラー処理

### 5. イベントテスト (`event_tests.rs`)

ドメインイベントの発行と収集をテストします。

```bash
cargo test --test event_tests
```

**テストケース:**
- パイプライン関連イベント（作成、無効化）
- ビルド関連イベント（作成、開始、完了）
- エージェント関連イベント（登録、切断）
- 複数操作でのイベント収集

### 6. 負荷テスト (`stress_tests.rs`)

システムの性能と負荷耐性をテストします。デフォルトでは無視されます。

```bash
cargo test --test stress_tests --ignored
```

**テストケース:**
- 大量ビルドの作成（1000件）
- パイプライン操作の並行実行（100件）
- エージェント間の負荷分散
- メモリ使用量の監視

### 7. E2Eテスト (`e2e_tests.rs`) 🌟

本番環境を模した完全なEnd-to-Endテスト。実際のインフラストラクチャを使用します。

```bash
# インフラストラクチャを起動してからE2Eテストを実行
docker-compose up -d postgres redis
cargo test --test e2e_tests -- --ignored --test-threads=1
```

**テストシナリオ:**
- 完全なCI/CDワークフロー（プロジェクト作成→ビルド→デプロイ）
- マルチプロジェクト並行ビルド（3プロジェクト × 5エージェント）
- ビルド失敗とリトライ
- エージェント障害とリカバリ
- パイプライン設定の動的更新

詳細は [e2e/README.md](e2e/README.md) を参照してください。

## 🛠️ テストユーティリティ

### TestFixture

`tests/common/mod.rs`で定義されている共通テストフィクスチャ。

**主な機能:**
- サービスとリポジトリのセットアップ
- テストデータの生成（プロジェクト、パイプライン、エージェント）
- イベントパブリッシャーへのアクセス

**使用例:**

```rust
#[tokio::test]
async fn my_test() {
    let fixture = TestFixture::new().await;
    let project = TestFixture::create_test_project();
    let config = TestFixture::create_test_pipeline_config();
    
    // テストロジック
}
```

## 📊 テスト実行方法

### すべてのテストを実行

```bash
cargo test --tests
```

### 特定のテストファイルを実行

```bash
cargo test --test <test_file_name>
```

### 負荷テストを含むすべてのテストを実行

```bash
cargo test --tests --ignored
```

### 詳細出力でテストを実行

```bash
cargo test --tests -- --nocapture
```

### 並列度を指定してテストを実行

```bash
cargo test --tests -- --test-threads=4
```

## 📈 テスト統計

現在のテストカバレッジ:

- **ライブラリテスト**: 90 passed (1 ignored)
- **統合テスト**: 4 passed
- **パイプラインテスト**: 5 passed
- **ビルドテスト**: 5 passed
- **エージェントテスト**: 6 passed
- **イベントテスト**: 4 passed
- **E2Eテスト**: 1 passed (5 ignored - インフラストラクチャ必要)
- **負荷テスト**: 4 ignored (オンデマンドで実行)

**合計**: 125 テスト (115 passed + 10 ignored)**

## 🎯 本番環境を模したテストシナリオ

### シナリオ1: 標準的なCI/CDワークフロー

```rust
// 1. プロジェクトとパイプラインの作成
// 2. コミットプッシュでビルドトリガー
// 3. エージェントへのジョブ割り当て
// 4. ビルド実行と完了
// 5. 結果の検証
```

実装: `integration_test.rs::test_end_to_end_workflow`

### シナリオ2: 並行ビルドの実行

```rust
// 1. 複数のエージェントを登録
// 2. 同時に複数のビルドを開始
// 3. エージェント間でジョブを分散
// 4. すべてのビルドが完了することを確認
```

実装: `build_tests.rs::test_concurrent_builds`

### シナリオ3: エージェント障害の処理

```rust
// 1. エージェントを登録してジョブを割り当て
// 2. エージェントの切断をシミュレート
// 3. デッドエージェントのクリーンアップ
// 4. システムが正常に動作し続けることを確認
```

実装: `agent_tests.rs::test_agent_cleanup_mechanism`

### シナリオ4: 大量ビルドの処理

```rust
// 1. 1000件のビルドを連続作成
// 2. パフォーマンスメトリクスの測定
// 3. すべてのビルドが正しく記録されることを確認
```

実装: `stress_tests.rs::test_high_volume_builds`

## 🔍 トラブルシューティング

### テストが失敗する場合

1. **依存関係の確認**
   ```bash
   cargo clean
   cargo build --tests
   ```

2. **詳細なエラー出力**
   ```bash
   RUST_BACKTRACE=1 cargo test --test <test_name> -- --nocapture
   ```

3. **単一テストの実行**
   ```bash
   cargo test --test <test_file> <test_function_name>
   ```

### タイムアウトの問題

長時間実行されるテストの場合、タイムアウトを調整できます:

```rust
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn my_long_test() {
    // テストコード
}
```

## 📝 テストの追加方法

1. 適切なテストファイルを選択または新規作成
2. `TestFixture`を使用してテスト環境をセットアップ
3. テストシナリオを実装
4. アサーションで期待される結果を検証
5. このREADMEを更新

### テンプレート

```rust
#[tokio::test]
async fn test_my_feature() {
    // Setup
    let fixture = TestFixture::new().await;
    
    // Execute
    let result = fixture.some_service.some_method().await;
    
    // Verify
    assert!(result.is_ok());
    let value = result.unwrap();
    assert_eq!(value.some_field(), expected_value);
}
```

## 🎓 ベストプラクティス

1. **独立性**: 各テストは他のテストから独立して実行できるようにする
2. **明確性**: テスト名は何をテストしているか明確にする
3. **速度**: 統合テストはインメモリリポジトリを使用して高速に実行
4. **網羅性**: 正常系と異常系の両方をテストする
5. **保守性**: 共通のセットアップは`TestFixture`に集約する

## 🚀 継続的インテグレーション

これらのテストはGitHub Actionsで自動実行されます:

- **プルリクエスト時**: すべての統合テスト（負荷テストを除く）
- **マージ時**: すべてのテスト（負荷テストを含む）
- **定期実行**: 夜間に完全なテストスイートを実行

設定ファイル: `.github/workflows/ci.yml`

## 📚 参考資料

- [Rustのテストガイド](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [Tokioのテストガイド](https://tokio.rs/tokio/topics/testing)
- [統合テストのベストプラクティス](https://doc.rust-lang.org/book/ch11-03-test-organization.html)

