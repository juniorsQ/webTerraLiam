<template>
  <section id="familias" class="section split-wrap">
    <div class="wrap grid-2">
      <article class="card pane">
        <h2>{{ kids.title }}</h2>
        <p class="lede">{{ kids.subtitle }}</p>
        <ul>
          <li v-for="item in kids.items" :key="item">{{ item }}</li>
        </ul>
      </article>
      <article class="card pane">
        <h2>{{ parents.title }}</h2>
        <p class="lede">{{ parents.subtitle }}</p>
        <ul>
          <li v-for="item in parents.items" :key="item">{{ item }}</li>
        </ul>
      </article>
    </div>
  </section>
</template>

<script setup>
defineProps({
  kids: { type: Object, required: true },
  parents: { type: Object, required: true },
})
</script>

<style scoped>
.split-wrap {
  padding-top: 0;
}

.pane {
  padding: 1.6rem 1.4rem;
}

.pane ul {
  margin: 0;
  padding: 0;
  list-style: none;
}

.pane li {
  position: relative;
  padding: 0.45rem 0 0.45rem 1.4rem;
  color: var(--ink);
}

.pane li::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0.85rem;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--teal);
}
</style>
