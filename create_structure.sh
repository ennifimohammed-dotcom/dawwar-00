#!/bin/bash

# Create Flutter project structure manually
BASE="/home/claude/dawwar"

# Directories
dirs=(
  "android/app/src/main/kotlin/com/dawwar/app"
  "android/app/src/main"
  "android/gradle/wrapper"
  "lib/core/constants"
  "lib/core/theme"
  "lib/core/utils"
  "lib/data/database"
  "lib/data/models"
  "lib/data/repositories"
  "lib/presentation/screens/home"
  "lib/presentation/screens/jamiya"
  "lib/presentation/screens/member"
  "lib/presentation/screens/payment"
  "lib/presentation/screens/report"
  "lib/presentation/widgets"
  "lib/presentation/providers"
  ".github/workflows"
)

for dir in "${dirs[@]}"; do
  mkdir -p "$BASE/$dir"
done

echo "Directories created!"
