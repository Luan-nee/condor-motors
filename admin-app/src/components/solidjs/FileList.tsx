import { deleteFile, getFiles, shareFile } from '@/core/controllers/archivos'
import { FileCard } from './FileCard'
import { createEffect, createSignal, For, on, Show } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { RefreshIcon } from './icons/RefreshIcon'
import { LoadingIcon } from './icons/LoadingIcon'
import { debounce } from '@/core/lib/utils'
import { CopyIcon } from './icons/CopyIcon'
import type { DOMElement } from 'solid-js/jsx-runtime'

const [fetchTrigger, setFetchTrigger] = createSignal(0)

export const FetchButton = () => {
  const [fetching, setFetching] = createSignal(false)

  const debounceSetFetching = debounce(setFetching, 500)

  const refreshData = () => {
    if (fetching()) {
      return
    }
    setFetchTrigger(fetchTrigger() + 1)
    setFetching(true)
    debounceSetFetching(false)
  }

  return (
    <button
      class="p-2 rounded text-white/50 flex items-center gap-1 hover:not-disabled:bg-white/5 hover:not-disabled:text-white/70 active:not-disabled:bg-white/10 active:not-disabled:text-white/80"
      disabled={fetching()}
      onClick={refreshData}
    >
      <Show when={fetching()}>
        <span class="text-sm font-medium">Actualizando...</span>
      </Show>
      <RefreshIcon
        class={`w-6 h-6 pointer-events-none ${fetching() ? 'animate-spin' : ''}`}
      />
    </button>
  )
}

const multipliers = [
  { value: 60, name: 'Minutos' },
  { value: 60 * 60, name: 'Horas' },
  { value: 60 * 60 * 24, name: 'Dias' },
  { value: 60 * 60 * 24 * 7, name: 'Semanas' }
]

interface Props {
  closeOverlay: () => void
  sharingFile?: FileEntity
}

const SharingFileForm = ({ closeOverlay, sharingFile }: Props) => {
  const [message, setMessage] = createSignal<string>('')
  const [downloadUrl, setDowloadUrl] = createSignal<string>('')
  const [duration, setDuration] = createSignal<number>(15)
  const [durationMultiplier, setDurationMultiplier] = createSignal<number>(60)
  const [expiresAt, setExpiresAt] = createSignal<string>('')

  const debounceSetMessage = debounce(setMessage, 3000)
  const updateMessage = (value: string) => {
    setMessage(value)
    debounceSetMessage('')
  }

  const handleSubmitForm = async (
    e: SubmitEvent & {
      currentTarget: HTMLFormElement
      target: DOMElement
    }
  ) => {
    e.preventDefault()

    if (sharingFile == null) {
      return
    }

    const { data, error } = await shareFile({
      filename: sharingFile.filename,
      duration: duration() * durationMultiplier() * 1000
    })

    if (error != null) {
      updateMessage(error.message)
      return
    }

    setExpiresAt(new Date(data.sharedFile.expiresAt).toLocaleString())
    setDowloadUrl(data.downloadUrl)
    updateMessage(data.message)
  }

  const handleBeforeInput = (
    e: InputEvent & {
      currentTarget: HTMLInputElement
      target: HTMLInputElement
    }
  ) => {
    if (
      !/^\d+$/.test(e.data ?? '') &&
      e.inputType !== 'deleteContentBackward' &&
      e.inputType !== 'deleteContentForward'
    ) {
      e.preventDefault()
    }
  }

  const handleInput = (
    e: InputEvent & {
      currentTarget: HTMLInputElement
      target: HTMLInputElement
    }
  ) => {
    const value = e.target.value
    setDuration(value === '' ? 0 : parseInt(value, 10))
  }

  return (
    <div
      class="inset-0 bg-black/30 fixed z-10 flex justify-center items-center"
      onclick={() => {
        closeOverlay()
      }}
    >
      <div
        class="border border-zinc-800 bg-[#212121] p-4 rounded-lg text-zinc-300 max-w-[460px] w-full"
        onclick={(e) => {
          e.stopPropagation()
        }}
      >
        <p class="font-semibold text-lg mb-4">
          Crea un enlace para compartir el archivo
        </p>
        <p class="mb-6">Por cuanto tiempo debe estar disponible este enlace?</p>
        <form class="space-y-6" onsubmit={handleSubmitForm}>
          <div class="flex items-stretch w-fit">
            <input
              class="px-3 py-2 border rounded-md 
                border-r-0 rounded-r-none w-24
                bg-zinc-900 border-zinc-700
                hover:border-zinc-500
                transition-colors
                hide-arrows"
              type="number"
              min={0}
              placeholder="15"
              onbeforeinput={handleBeforeInput}
              oninput={handleInput}
              value={duration()}
            />
            <select
              class="px-3 py-2 border
                border-l-0 rounded-l-none
                bg-zinc-900 border-zinc-700
                transition-colors rounded-md
                hover:border-zinc-500 hide-arrows"
              value={durationMultiplier()}
              onchange={(e) => {
                setDurationMultiplier(parseInt(e.target.value))
              }}
            >
              <For each={multipliers}>
                {(item) => <option value={item.value}>{item.name}</option>}
              </For>
            </select>
          </div>

          <Show when={downloadUrl().length > 0}>
            <div>
              <p class="text-sm pb-1 font-semibold">
                Expiracion: {expiresAt()}
              </p>
              <div class="bg-[#0f0f0f] px-4 py-2 border border-zinc-600 rounded-xl flex gap-4 items-center hover:border-blue-500/70">
                <input
                  class="w-full overflow-hidden text-ellipsis"
                  type="text"
                  value={downloadUrl()}
                  readonly
                />
                <button
                  class="p-2 hover:text-white hover:bg-white/10 rounded active:bg-white/15"
                  type="button"
                  onclick={() => {
                    navigator.clipboard.writeText(downloadUrl())
                    updateMessage('Enlace copiado al portapapeles')
                  }}
                >
                  <CopyIcon class="w-6 h-6" />
                </button>
              </div>
            </div>
          </Show>

          <div class="flex justify-end gap-4 items-center">
            <Show when={message().length > 0}>
              <p class="text-sm mr-auto">{message()}</p>
            </Show>
            <button
              class="font-semibold rounded-md border px-4 py-2 text-sm h-fit
                  text-white/80 border-zinc-600 
                  hover:not-disabled:text-white hover:not-disabled:bg-white/10 hover:not-disabled:border-zinc-500
                  transition-colors"
              onclick={() => {
                closeOverlay()
              }}
              type="button"
            >
              Cerrar
            </button>
            <button
              class="font-semibold rounded-md border px-4 py-2 text-sm h-fit
                text-black/80 bg-zinc-300 border-zinc-800 
                hover:not-disabled:text-black hover:not-disabled:bg-white
                transition-colors text-nowrap"
              type="submit"
            >
              Crear enlace
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export const FileList = () => {
  const [isLoading, setLoading] = createSignal<boolean>(true)
  const [files, setFiles] = createSignal<FileEntity[]>([])
  const [error, setError] = createSignal<string>('')
  const [isOverlayVisible, setOverlayVisibility] = createSignal<boolean>(false)
  const [sharingFile, setSharingFile] = createSignal<FileEntity>()

  const fetchData = async () => {
    setLoading(true)
    const { data: apiData, error: apiError } = await getFiles()
    setLoading(false)

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    setError('')
    setFiles(apiData)
  }

  createEffect(
    on(fetchTrigger, () => {
      fetchData()
    })
  )

  const deleteItem = (id: number) => async () => {
    const { error: apiError } = await deleteFile({ id })

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    const newData = files().filter((f) => f.id !== id)
    setFiles(newData)
  }

  const showOverlay = (file: FileEntity) => async () => {
    setSharingFile(file)
    setOverlayVisibility(true)
  }

  const closeOverlay = () => {
    setOverlayVisibility(false)
    setSharingFile()
  }

  return (
    <div class="grow flex flex-col gap-3 px-3 overflow-y-auto scrollbar-thin">
      <Show when={error().length > 0}>
        <div class="text-sm text-red-400 font-semibold">{error()}</div>
      </Show>
      <Show when={files().length < 1 && error().length < 1}>
        <p class="text-sm font-semibold">Aún no ha subido ningún archivo</p>
      </Show>
      <Show when={isLoading() && files().length < 1}>
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <LoadingIcon class="w-6 h-6 animate-spin" />
          <p class="text-sm font-semibold">Loading files...</p>
        </div>
      </Show>
      <For each={files()}>
        {(item) => (
          <FileCard
            file={item}
            deleteItem={deleteItem(item.id)}
            shareFile={showOverlay(item)}
          />
        )}
      </For>
      <Show when={isOverlayVisible()}>
        <SharingFileForm
          closeOverlay={closeOverlay}
          sharingFile={sharingFile()}
        />
      </Show>
    </div>
  )
}
