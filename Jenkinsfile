// Jenkins pipeline: mirrors .github/workflows/ci.yml and runs inside a
// throwaway Docker container so every build is an isolated sandbox.
//
// Jenkins prerequisites:
//   - Docker Pipeline plugin + Docker available on the agent
// (DesignWear's dependencies are all public, so no deploy keys are needed.)
pipeline {
    agent {
        docker {
            // Pin to the Flutter version you develop against.
            image 'ghcr.io/cirruslabs/flutter:stable'
            args '-e HOME=/tmp/home'
        }
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds(abortPrevious: true)
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        PUB_CACHE = "${WORKSPACE}/.pub-cache"
        CI = 'true'
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    # .env files are pubspec assets but gitignored; empty
                    # placeholders satisfy the asset check. No real secrets
                    # reach the sandbox.
                    printf '# CI placeholder\n' | tee .env .env.local >/dev/null
                    flutter --version
                    flutter pub get
                '''
            }
        }

        stage('Analyze') {
            steps {
                sh 'flutter analyze'
            }
        }

        stage('Format check') {
            steps {
                // Non-blocking, same as GitHub CI.
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'dart format --output=none --set-exit-if-changed .'
                }
            }
        }

        stage('Test') {
            steps {
                sh '''
                    flutter test --machine --coverage > test-results.json || EXIT=$?
                    exit ${EXIT:-0}
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'coverage/lcov.info, test-results.json',
                                     allowEmptyArchive: true
                }
            }
        }

        stage('Build web') {
            steps {
                sh 'flutter build web --release'
            }
        }
    }

    post {
        cleanup {
            cleanWs()
        }
    }
}
