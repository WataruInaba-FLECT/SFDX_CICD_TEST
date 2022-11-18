# Using Salesforce CLI with Github Actions

Github Actions を使用して salesforce に CI/CD を導入します。
以下、既存 yml ファイルの意味に関してコメントにて使用方法を記載。
Github Actions での yml の記載方法に関しては公式サイトを参照<br>
<https://docs.github.com/ja/actions/using-workflows/workflow-syntax-for-github-actions>

```yaml
# The name of your workflow. GitHub displays the names of your workflows on your repository's "Actions" tab.
# If you omit name, GitHub sets it to the workflow file path relative to the root of the repository.
name: "Salesforce Deploy Check"

# ワークフローを自動的にトリガーするには、on を使用してワークフローを実行する原因となるイベントを定義します。
# ワークフローをトリガーできる 1 つまたは複数のイベントを定義することも、時間スケジュールを設定することもできます。
on:
    pull_request:
        # 一部のイベントには、ワークフローを実行するタイミングをより細かく制御できるアクティビティの種類があります。 on.<event_name>.types を使用して、ワークフロー実行をトリガーするイベント アクティビティの種類を定義します。
        types:
            - opened
            - synchronize
            - reopened
        # 一部のイベントには、ワークフローを実行するタイミングをより細かく制御できるフィルターがあります。
        # たとえば、push イベントの branches フィルターでは、プッシュが発生したときではなく、branches フィルターと同じブランチに対してプッシュが発生したときのみ、ワークフローを実行できます。
        branches:
            - develop
# ワークフロー実行は、既定で並列実行される 1 つ以上の jobs で構成されます。(実際に実行したいことをjobsに記載する)
jobs:
    # ジョブへの一意の識別子の指定には、jobs.<job_id> を使います(ここではbuildと命名。)
    build:
        # runs-on : ジョブを実行するマシンの種類を定義します。（対象はGitHub ホステッド ランナーより選択する。windows サーバー ,Linuxならubuntuのみ、あとはMacosが選択可能）
        runs-on: ubuntu-latest
        # ジョブには、ステップと呼ばれる一連のタスクが含まれています。ステップでは、コマンドの実行、セットアップタスクの実行、自分のリポジトリや公開リポジトリ、Dockerレジストリで公開されているアクションの実行が可能です。
        steps:
            # uses : 頻繁に繰り返される複雑なタスクは、GitHub Actions プラットフォームで、アクションとして事前定義されています。jobsで利用するリポジトリをチェックアウトする作業を簡素化する
            # ためにactions/checkoutを利用します。usesキーワードで指定したアクションを実行します。
            - uses: actions/checkout@v3
              with:
                  # The branch, tag or SHA to checkout. When checking out the repository that
                  # ${{github.head_ref}}: gitHub ActionsのWorkflow実行内でRef（Branch）名を取得する方法.ここではHEADのbranch名を取得している。
                  ref: ${{github.head_ref}}

              # Node.jsのインストール
            - uses: actions/setup-node@v1
              with:
                  node-version: ">=14"
                  # ローカルにキャッシュされた最新の Node.js バージョン、または actions/node-versions から最新バージョンを取得します。
                  check-latest: true

            - name: "Install Salesforce CLI"
              # sfdx コマンドを直接node_modulsから実行（パスを通してない）
              run: |
                  npm install sfdx-cli
                  node_modules/sfdx-cli/bin/run --version
                  node_modules/sfdx-cli/bin/run plugins --core

            - name: "Populate auth file with SFDX_URL secret"
              # bash を使用してgithubのsecretsから認証用URLを取得し、SFDX_QAに格納
              shell: bash
              run: "echo ${{secrets.SFDX_LR_TEST_URL}} > SFDX_QA"

            - name: "Authenticate against developer sandbox"
              # ファイル内に保存されたSFDX認証URLを使用して、組織を認証する。-fでファイル指定。-sでデフォルト指定。-a はエイリアス
              run: node_modules/sfdx-cli/bin/run force:auth:sfdxurl:store -f SFDX_QA -s -a LRQA

            - name: "Convert metadata"
              # sandboxからソースをメタデータ形式で取得し、releaseフォルダに格納する
              run: |
                  mkdir ./release
                  node_modules/sfdx-cli/bin/run force:source:convert -d ./release

            - name: "Deploy check"
              # sandboxへのデプロイチェック。--checkonly：デプロイされたメタデータを検証し、すべての Apex テストを実行しますが、デプロイが org に保存されることはありません。
              # -x: マニフェストファイルのパス指定。-u: 対象の組織、ユーザーネームを指定する。
              run: node_modules/sfdx-cli/bin/run force:source:deploy --checkonly -x ./release/package.xml -u ${{secrets.SFDX_DEV_USER_NAME}}
```
